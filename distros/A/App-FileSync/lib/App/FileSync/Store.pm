package App::FileSync::Store;

# The server's view of one repo: the master tree, its index (master.json), the
# per-client bases, the trash, the journal and the session lock, all under
# ROOT/master/REPO and ROOT/.filesync/repos/REPO.

use App::FileSync::Platform;

use strict;
use warnings;
use autodie qw(:all);

use File::Basename qw(dirname);
use File::Spec;
use Sub::Private { mode => 'enforce' };

use parent -norequire, 'App::FileSync::Base';
use App::FileSync::Base;

use App::FileSync qw(json_encode json_decode read_text write_atomic validate_relpath validate_client_id validate_repo_name);
use App::FileSync::Args qw(named);
use App::FileSync::Config;
use App::FileSync::Constants qw($STALE_TEMP_SECONDS $TRASH_DAYS);
use App::FileSync::I18N qw(strip_location throw);
use App::FileSync::IO qw(append_line ensure_dir install_file);
use App::FileSync::Ignore;
use App::FileSync::Lock;
use App::FileSync::Scan;
use App::FileSync::Trash;

use version; our $VERSION = version->declare('0.001.5');

=encoding utf8

=head1 NAME

App::FileSync::Store - the server-side files of one repo

=head1 SYNOPSIS

	my $store = App::FileSync::Store->new(root => '/srv/filesync', repo => 'docs');
	my $lock  = $store->acquire_lock() or die 'busy';
	my $index = $store->load_index();
	my $scan  = $store->walk_master($index);
	$store->save_index($scan->{manifest});

=head1 METHODS

=head2 new

Purpose: open a repo on the server.

Args: C<root>, C<repo>, optional C<config> (the repo config, read from disk
when omitted) and C<language>.

Returns: the store.

Side Effects: reads the repo config.

Usage:

	my $store = App::FileSync::Store->new(root => $root, repo => $repo);

=head3 EXAMPLE

	my $store = App::FileSync::Store->new(root => '/srv/filesync', repo => 'docs');
	print $store->master_dir, "\n";

=head3 API SPECIFICATION

=head4 INPUT

	{
		root     => { type => 'string', min => 1 },
		repo     => { type => 'string', min => 1 },
		config   => { type => 'hashref', optional => 1 },
		language => { type => 'string', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'object', isa => 'App::FileSync::Store' }

=head3 MESSAGES

	Key              Meaning                       Resolution
	args.invalid     root or repo missing          pass both
	store.bad_repo   the repo name is not an id    use letters, digits, '.', '_', '-'
	config.no_repo   the repo does not exist       filesync-admin repo create

=head3 FORMAL SPECIFICATION

	new(r, n, c) = ⟨root ↦ r, repo ↦ n, config ↦ c or load_repo(r, n), ignore ↦ Ignore(config.ignore)⟩

=cut

sub new {
	my $class = shift;
	my $args = named(\@_, {
		root     => { type => 'string', min => 1 },
		repo     => { type => 'string', min => 1 },
		config   => { type => 'hashref', optional => 1 },
		language => { type => 'string', optional => 1 },
	}, 'Store->new');

	# The name becomes a directory under the root, so it must be a plain id
	# before any path is built from it.
	my ($ok, $reason) = validate_repo_name($args->{repo});
	throw('store.bad_repo', { reason => $reason }) unless $ok;

	my $config = $args->{config} || App::FileSync::Config::load_repo($args->{root}, $args->{repo});

	return bless {
		root     => $args->{root},
		repo     => $args->{repo},
		language => $args->{language},
		config   => $config,
		ignore   => App::FileSync::Ignore->new(patterns => $config->{ignore}),
	}, $class;
}

=head2 root

Documented with L</journal_path> below.

=head2 repo

Documented with L</journal_path> below.

=head2 config

Documented with L</journal_path> below.

=head2 master_dir

Documented with L</journal_path> below.

=head2 meta_dir

Documented with L</journal_path> below.

=head2 index_path

Documented with L</journal_path> below.

=head2 trash_dir

Documented with L</journal_path> below.

=head2 lock_path

Documented with L</journal_path> below.

=head2 journal_path

Purpose: where the repo's pieces live.

Args: none.

Returns: the server root, the repo name, the config hashref, and the paths of
the master tree (F<ROOT/master/REPO>), the metadata directory, the index
(F<master.json>), the trash, the lock file and this month's journal
(F<journal/YYYY-MM.jsonl>, UTC).

Side Effects: none.

Usage:

	my $master = $store->master_dir;

=head3 EXAMPLE

	print join("\n", $store->master_dir, $store->index_path, $store->journal_path), "\n";

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'self', type => 'object' } ]

=head4 OUTPUT

	{ type => 'string' }

=head3 MESSAGES

None.

=head3 FORMAL SPECIFICATION

	master_dir = root / "master" / repo
	meta_dir = root / ".filesync" / "repos" / repo
	index_path = meta_dir / "master.json"
	journal_path = meta_dir / "journal" / yyyy-mm(now) ⁀ ".jsonl"

=cut

sub root {
	my ($self) = @_;

	return $self->{root};
}

sub repo {
	my ($self) = @_;

	return $self->{repo};
}

sub config {
	my ($self) = @_;

	return $self->{config};
}

sub master_dir {
	my ($self) = @_;

	return File::Spec->catdir($self->{root}, 'master', $self->{repo});
}

sub meta_dir {
	my ($self) = @_;

	return App::FileSync::Config::repo_meta_dir($self->{root}, $self->{repo});
}

sub index_path {
	my ($self) = @_;

	return File::Spec->catfile($self->meta_dir(), 'master.json');
}

sub trash_dir {
	my ($self) = @_;

	return File::Spec->catdir($self->meta_dir(), 'trash');
}

sub lock_path {
	my ($self) = @_;

	return File::Spec->catfile($self->meta_dir(), 'locks', 'repo.lock');
}

sub journal_path {
	my ($self) = @_;

	my @t = gmtime();
	return File::Spec->catfile($self->meta_dir(), 'journal',
		sprintf('%04d-%02d.jsonl', $t[5] + 1900, $t[4] + 1));
}

=head2 base_path

Purpose: where a client's base (its state at its last sync) is stored.

Args: C<$client>, a client id.

Returns: F<META/clients/CLIENT.json>.

Side Effects: none.

Usage:

	my $path = $store->base_path('laptop-1');

=head3 EXAMPLE

	unlink $store->base_path($client) if $forget;

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'self',   type => 'object' },
		{ name => 'client', type => 'string', min => 1 },
	]

=head4 OUTPUT

	{ type => 'string', min => 1 }

=head3 MESSAGES

	Key              Meaning                              Resolution
	store.bad_client the id is not a valid client id      use letters, digits, . _ -

=head3 FORMAL SPECIFICATION

	pre client ∈ Id
	base_path(client) = meta_dir / "clients" / client ⁀ ".json"

=cut

sub base_path {
	my ($self, $client) = @_;

	# The id becomes a file name, so it must not be able to climb out of the
	# clients directory.
	my ($ok, $reason) = validate_client_id($client);
	$self->_throw('store.bad_client', { reason => $reason }) unless $ok;

	return File::Spec->catfile($self->meta_dir(), 'clients', "$client.json");
}

=head2 acquire_lock

Purpose: take the repo's session lock without waiting.

Args: none.

Returns: the lock handle, or C<undef> when another session holds it.

Side Effects: creates the lock file.

Usage:

	my $lock = $store->acquire_lock() or return refuse('locked');

=head3 EXAMPLE

	if (my $lock = $store->acquire_lock) { ... }

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'self', type => 'object' } ]

=head4 OUTPUT

	{ type => 'handle', optional => 1 }

=head3 MESSAGES

	Key         Meaning                         Resolution
	io.append   the lock file cannot be made    check permissions

=head3 FORMAL SPECIFICATION

	acquire_lock = Lock::acquire(lock_path, nonblock)

=cut

sub acquire_lock {
	my ($self) = @_;

	return App::FileSync::Lock::acquire(path => $self->lock_path(), nonblock => 1);
}

=head2 abs_path

Purpose: the absolute path in the master for a relative path.

Args: C<$rel>.

Returns: the path under L</master_dir>.

Side Effects: none.  Raises if C<$rel> is unsafe or if a directory on the way
is a symlink, so nothing can be written outside the master through one.

Usage:

	my $abs = $store->abs_path($path);

=head3 EXAMPLE

	my $abs = $store->abs_path('notes/plan.txt');

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'self', type => 'object' },
		{ name => 'rel',  type => 'string' },
	]

=head4 OUTPUT

	{ type => 'string', min => 1 }

=head3 MESSAGES

	Key              Meaning                                  Resolution
	path.unsafe      the path fails validate_relpath          rename the file
	store.symlink    a parent directory is a symlink          remove the symlink

=head3 FORMAL SPECIFICATION

	pre rel ∈ SafePath ∧ ∀ a : ancestors(master / rel) ∩ under(master) • kind a ≠ symlink
	abs_path(rel) = master / rel

=cut

sub abs_path {
	my ($self, $rel) = @_;

	my ($ok, $reason) = validate_relpath($rel);
	$self->_throw('path.unsafe', { path => $rel, reason => $reason }) unless $ok;

	$self->_assert_no_symlinked_parent($rel);

	return File::Spec->catfile($self->master_dir(), split m{/}, $rel);
}

=head2 load_index

Documented with L</save_base> below.

=head2 save_index

Documented with L</save_base> below.

=head2 load_base

Documented with L</save_base> below.

=head2 save_base

Purpose: read and write the master's index and a client's base.

Args: C<save_index(\%entries)>; C<load_base($client)>;
C<save_base($client, \%entries)>.

Returns: the entries hashref (empty when the file does not exist); 1 for the
save methods.

Side Effects: the save methods replace the file atomically.

Usage:

	my $index = $store->load_index();
	$store->save_base($client, $base_after);

=head3 EXAMPLE

	my $base = $store->load_base('laptop-1');
	print scalar(keys %{$base}), " paths known to laptop-1\n";

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'self',    type => 'object' },
		{ name => 'client',  type => 'string', optional => 1 },
		{ name => 'entries', type => 'hashref', optional => 1 },
	]

=head4 OUTPUT

	{ type => 'hashref' }

=head3 MESSAGES

	Key            Meaning                       Resolution
	config.parse   the file is not valid JSON    run filesync-admin reindex
	io.write       the file cannot be written    check space

=head3 FORMAL SPECIFICATION

	load(p) = json(FS(p)).entries if p ∈ dom FS ∧ is a hash, else ∅
	save(p, e): FS'(p) = json(⟨version ↦ 1, entries ↦ e⟩) ⁀ "\n"

=cut

sub load_index {
	my ($self) = @_;

	return $self->_load_entries($self->index_path());
}

sub save_index {
	my ($self, $entries) = @_;

	return $self->_save_entries($self->index_path(), $entries);
}

sub load_base {
	my ($self, $client) = @_;

	return $self->_load_entries($self->base_path($client));
}

sub save_base {
	my ($self, $client, $entries) = @_;

	return $self->_save_entries($self->base_path($client), $entries);
}

=head2 walk_master

Purpose: scan the master, reusing indexed hashes where size and mtime match.

Args: optional C<\%cache> (usually the current index; C<{}> forces a rehash).

Returns: the L<App::FileSync::Scan/scan> result: C<{ manifest, stats, skipped }>.

Side Effects: reads the master tree.

Usage:

	my $scan = $store->walk_master($store->load_index);

=head3 EXAMPLE

	my $fresh = $store->walk_master({});
	printf "%d files\n", $fresh->{stats}{files};

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'self',  type => 'object' },
		{ name => 'cache', type => 'hashref', optional => 1 },
	]

=head4 OUTPUT

	{ type => 'hashref' }

=head3 MESSAGES

	Key               Meaning                     Resolution
	store.no_master   the master directory is gone   restore it or recreate the repo

=head3 FORMAL SPECIFICATION

	pre isdir(master_dir)
	walk_master(c) = scan(master_dir, ignore, c)

=cut

sub walk_master {
	my ($self, $cache) = @_;

	my $master = $self->master_dir();
	$self->_throw('store.no_master', { path => $master }) unless -d $master;

	return App::FileSync::Scan::scan(
		root   => $master,
		ignore => $self->{ignore},
		cache  => $cache || {},
	);
}

=head2 ensure_parent

Purpose: create the directory a master path will be written into.

Args: C<$rel>.

Returns: the parent directory.

Side Effects: creates missing directories.

Usage:

	$store->ensure_parent($path);

=head3 EXAMPLE

	$store->ensure_parent('new/deep/dir/file.txt');

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'self', type => 'object' },
		{ name => 'rel',  type => 'string', min => 1 },
	]

=head4 OUTPUT

	{ type => 'string', min => 1 }

=head3 MESSAGES

As for L</abs_path>, plus C<io.mkdir>.

=head3 FORMAL SPECIFICATION

	isdir'(dirname(abs_path(rel)))

=cut

sub ensure_parent {
	my ($self, $rel) = @_;

	return ensure_dir(dirname($self->abs_path($rel)));
}

=head2 temp_file

Purpose: an exclusive temporary file beside a master path.

Args: C<$rel>, the path the temporary file will become.

Returns: C<[ $filehandle, $path ]>.

Side Effects: creates the file (and its directory).

Usage:

	my ($fh, $temp) = @{ $store->temp_file($path) };

=head3 EXAMPLE

	my ($fh, $temp) = @{ $store->temp_file('notes/plan.txt') };
	print {$fh} $content;
	close $fh;
	$store->commit_temp('notes/plan.txt', $temp, time, oct(644));

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'self', type => 'object' },
		{ name => 'rel',  type => 'string', min => 1 },
	]

=head4 OUTPUT

	{ type => 'arrayref', min => 2, max => 2 }

=head3 MESSAGES

As for L</abs_path>, plus C<io.temp>.

=head3 FORMAL SPECIFICATION

	temp_file(rel) = App::FileSync::IO::temp_file(dirname(abs_path(rel)))

=cut

sub temp_file {
	my ($self, $rel) = @_;

	return App::FileSync::IO::temp_file(dirname($self->abs_path($rel)));
}

=head2 commit_temp

Purpose: move a verified temporary file into the master.

Args: C<$rel>, C<$temp>, optional C<$mtime> and C<$mode>.

Returns: the absolute path written.

Side Effects: see L<App::FileSync::IO/install_file>.

Usage:

	$store->commit_temp($path, $temp, $mtime, $mode);

=head3 EXAMPLE

	$store->commit_temp('a.txt', $temp, 1_700_000_000, oct(600));

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'self',  type => 'object' },
		{ name => 'rel',   type => 'string', min => 1 },
		{ name => 'temp',  type => 'string', min => 1 },
		{ name => 'mtime', type => 'number', optional => 1 },
		{ name => 'mode',  type => 'integer', optional => 1 },
	]

=head4 OUTPUT

	{ type => 'string', min => 1 }

=head3 MESSAGES

As for L<App::FileSync::IO/install_file> and L</abs_path>.

=head3 FORMAL SPECIFICATION

	commit_temp(rel, t, m, mode) = install_file(t, abs_path(rel), m, mode)

=cut

sub commit_temp {
	my ($self, $rel, $temp, $mtime, $mode) = @_;

	return install_file($temp, $self->abs_path($rel), $mtime, $mode);
}

=head2 move_to_trash

Purpose: move a master path into the repo's trash.

Args: C<$rel>, optional C<$epoch>.

Returns: where it went, or C<undef> if it was not there.

Side Effects: see L<App::FileSync::Trash/move_to_trash>.

Usage:

	my $trashed = $store->move_to_trash($path, time);

=head3 EXAMPLE

	my $where = $store->move_to_trash('old/report.txt');

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'self',  type => 'object' },
		{ name => 'rel',   type => 'string', min => 1 },
		{ name => 'epoch', type => 'number', optional => 1 },
	]

=head4 OUTPUT

	{ type => 'string', optional => 1 }

=head3 MESSAGES

As for L<App::FileSync::Trash/move_to_trash> and L</abs_path>.

=head3 FORMAL SPECIFICATION

	abs_path(rel) ∉ dom FS ⇒ result = ⊥
	abs_path(rel) ∈ dom FS ⇒ result = Trash::move_to_trash(abs_path(rel), rel, trash_dir, epoch)

=cut

sub move_to_trash {
	my ($self, $rel, $epoch) = @_;

	my $abs = $self->abs_path($rel);
	return undef unless -e $abs || -l $abs;	## no critic (Subroutines::ProhibitExplicitReturnUndef)

	return App::FileSync::Trash::move_to_trash(
		src   => $abs,
		rel   => $rel,
		root  => $self->trash_dir(),
		epoch => defined $epoch ? $epoch : time,
	);
}

=head2 clean_stale_temps

Documented with L</prune_trash> below.

=head2 prune_trash

Purpose: housekeeping at the start of a session.

Args: C<clean_stale_temps(max_age =E<gt> SECONDS)>;
C<prune_trash(days =E<gt> N, dry_run =E<gt> BOOL)>.  Defaults: one hour, and
the repo's C<trash_days> (30).

Returns: the number of temporaries removed; the arrayref of trash buckets
removed.

Side Effects: deletes stale temporaries from the master and expired trash.

Usage:

	$store->clean_stale_temps();
	$store->prune_trash();

=head3 EXAMPLE

	my $pruned = $store->prune_trash(dry_run => 1);

=head3 API SPECIFICATION

=head4 INPUT

	{
		max_age => { type => 'integer', min => 0, optional => 1 },
		days    => { type => 'number', optional => 1 },
		dry_run => { type => 'boolean', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'scalar' }

=head3 MESSAGES

None.

=head3 FORMAL SPECIFICATION

	clean_stale_temps = Scan::clean_stale_temps(master_dir, age)
	prune_trash = Trash::prune(trash_dir, days)

=cut

sub clean_stale_temps {
	my ($self, %args) = @_;

	my $master = $self->master_dir();
	return 0 unless -d $master;

	return App::FileSync::Scan::clean_stale_temps(
		root    => $master,
		max_age => defined $args{max_age} ? $args{max_age} : $STALE_TEMP_SECONDS,
	);
}

sub prune_trash {
	my ($self, %args) = @_;

	return App::FileSync::Trash::prune(
		root    => $self->trash_dir(),
		days    => defined $args{days} ? $args{days} : ($self->{config}{trash_days} || $TRASH_DAYS),
		dry_run => $args{dry_run},
	);
}

=head2 journal

Purpose: append an event to this month's journal.

Args: C<\%event>; a C<ts> (now) is added.

Returns: 1.

Side Effects: appends one JSON line, creating the journal directory.

Usage:

	$store->journal({ client => $id, action => 'push', path => $path, result => 'ok' });

=head3 EXAMPLE

	$store->journal({ action => 'reindex', files => 10, result => 'ok' });

=head3 API SPECIFICATION

=head4 INPUT

	[
		{ name => 'self',  type => 'object' },
		{ name => 'event', type => 'hashref' },
	]

=head4 OUTPUT

	{ type => 'integer', min => 1, max => 1 }

=head3 MESSAGES

	Key         Meaning                        Resolution
	io.append   the journal cannot be written  check space

=head3 FORMAL SPECIFICATION

	FS'(journal_path) = FS(journal_path) ⁀ json({ts ↦ now} ⊕ event) ⁀ "\n"

=cut

sub journal {
	my ($self, $event) = @_;

	append_line($self->journal_path(), json_encode({ ts => time, %{$event} }));
	return 1;
}

# _assert_no_symlinked_parent
# Purpose:     refuse to write through a symlinked directory in the master.
# Entry:       $rel has passed validate_relpath.
# Exit:        returns 1.
# Side effects: raises store.symlink.  Stops at the first missing directory:
#              nothing below it can be a symlink yet.
sub _assert_no_symlinked_parent :Private {
	my ($self, $rel) = @_;

	my @parts = split m{/}, $rel;
	pop @parts;

	my $current = $self->master_dir();
	for my $part (@parts) {
		$current = File::Spec->catfile($current, $part);
		last unless -e $current || -l $current;
		$self->_throw('store.symlink', { path => $current }) if -l $current;
	}

	return 1;
}

# _load_entries
# Purpose:     read an index or base file.
# Entry:       $path may not exist.
# Exit:        returns the entries hashref (empty for a missing file or one
#              without an entries hash).
# Side effects: raises config.parse for a corrupt file.
sub _load_entries :Private {
	my ($self, $path) = @_;

	return {} unless -e $path;

	my $text = read_text($path);
	my $document = eval { json_decode($text) };
	$self->_throw('config.parse', { path => $path, error => strip_location($@) }) if $@;

	return (ref($document) eq 'HASH' && ref($document->{entries}) eq 'HASH') ? $document->{entries} : {};
}

# _save_entries
# Purpose:     write an index or base file.
# Entry:       $entries may be undef (written as empty).
# Exit:        returns 1.
# Side effects: replaces $path atomically.
sub _save_entries :Private {
	my ($self, $path, $entries) = @_;

	write_atomic($path, json_encode({ version => 1, entries => $entries || {} }) . "\n");
	return 1;
}

1;

__END__

=head1 LIMITATIONS

=over 4

=item * The index and every base are rewritten whole at the end of each
session, so a session costs O(files) writes even when one file changed.

=item * The symlink check walks the existing directories of each path on
every write; a symlink created by an administrator between the check and the
write is not caught.

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
