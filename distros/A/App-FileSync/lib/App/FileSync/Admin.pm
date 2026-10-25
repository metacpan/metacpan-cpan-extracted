package App::FileSync::Admin;

# Server-side administration: the operations behind filesync-admin.  Every
# method works directly on the server root; none of them talks to a client.

use App::FileSync::Platform;

use strict;
use warnings;
use autodie qw(:all);

use File::Basename qw(dirname);
use File::Spec;
use List::Util qw(any);
use Readonly;
use Sub::Private { mode => 'enforce' };

use parent 'App::FileSync::Base';

use App::FileSync qw(json_decode validate_relpath validate_repo_name validate_client_id parse_since parse_until);
use App::FileSync::Args qw(named positional);
use App::FileSync::Config;
use App::FileSync::Constants qw($DEFAULT_SERVER_ROOT $ROLE_CLIENT @ROLES);
use App::FileSync::I18N qw(os_error);
use App::FileSync::Ignore;
use App::FileSync::IO qw(ensure_dir list_dir open_file sha256_file);
use App::FileSync::Settings;
use App::FileSync::Store;
use App::FileSync::Trash;
use App::FileSync::Verify;

use version; our $VERSION = version->declare('0.001.2');

# The per-repo metadata directories a new repo starts with.
Readonly my @META_DIRS => qw(clients trash journal locks);

# Journal files are one per month, named YYYY-MM.jsonl.
Readonly my $JOURNAL_FILE => qr/\.jsonl\z/;

# A trash date argument.
Readonly my $DATE => qr/\A\d{4}-\d{2}-\d{2}\z/;

# Arguments most methods take.
my %REPO = (repo => { type => 'string', min => 1 });

=encoding utf8

=head1 NAME

App::FileSync::Admin - server-side repo, client and recovery administration

=head1 SYNOPSIS

	my $admin = App::FileSync::Admin->new(root => '/srv/filesync');
	$admin->repo_create(name => 'docs');
	$admin->client_allow(repo => 'docs', client => 'laptop');
	my $report = $admin->verify(repo => 'docs', deep => 1);

=head1 DESCRIPTION

The library behind C<filesync-admin>.  Methods return hashrefs or arrayrefs
for the command line to print (or encode as JSON) and raise catalogued
errors (see L<App::FileSync::I18N>) on failure.

=head1 METHODS

=head2 new

Purpose: an administrator for one server root.

Args: optional C<root> (default C<FILESYNC_ROOT>, then F</srv/filesync>),
C<logger> (default from L<App::FileSync::Settings>), C<language>.

Returns: the object.

Side Effects: builds a logger from the settings when none is given.

Usage:

	my $admin = App::FileSync::Admin->new(root => $root);

=head3 EXAMPLE

	my $admin = App::FileSync::Admin->new;
	print $admin->root, "\n";	# /srv/filesync unless FILESYNC_ROOT says otherwise

=head3 API SPECIFICATION

=head4 INPUT

	{
		root     => { type => 'string', optional => 1 },
		logger   => { type => 'object', optional => 1 },
		language => { type => 'string', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'object', isa => 'App::FileSync::Admin' }

=head3 MESSAGES

	Key            Meaning                  Resolution
	args.invalid   an argument is malformed fix the call

=head3 FORMAL SPECIFICATION

	root' = first non-empty ⟨root, FILESYNC_ROOT, "/srv/filesync"⟩

=cut

sub new {
	my $class = shift;
	my $args = named(\@_, {
		root     => { type => 'string', optional => 1 },
		logger   => { type => 'object', optional => 1 },
		language => { type => 'string', optional => 1 },
	}, 'Admin->new');

	my ($root) = grep { defined && length } $args->{root}, $ENV{FILESYNC_ROOT}, $DEFAULT_SERVER_ROOT;

	return bless {
		root     => $root,
		language => $args->{language},
		logger   => $args->{logger} || App::FileSync::Settings::logger(),
	}, $class;
}

=head2 root

Purpose: the server root this object administers.

Args: none.

Returns: the path.

Side Effects: none.

Usage:

	my $root = $admin->root;

=head3 EXAMPLE

	print $admin->root, "\n";

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'self', type => 'object' } ]

=head4 OUTPUT

	{ type => 'string', min => 1 }

=head3 MESSAGES

None.

=head3 FORMAL SPECIFICATION

	root = self.root

=cut

sub root {
	my ($self) = @_;

	return $self->{root};
}

=head2 repo_create

Purpose: create a repo: its master tree, metadata directories, policy and an
empty index.

Args: C<name> (a repo id), optional C<trash_days>, C<max_deletes>,
C<max_delete_percent> (non-negative integers) and C<ignore> (patterns; the
default ignore list when absent or empty).

Returns: C<{ name, master, config }> (the master and config paths).

Side Effects: creates F<ROOT/master/NAME> and F<ROOT/.filesync/repos/NAME>.

Usage:

	$admin->repo_create(name => 'docs', trash_days => 60);

=head3 EXAMPLE

	my $made = $admin->repo_create(name => 'photos', ignore => [ '*.tmp', '/cache/' ]);
	print "master at $made->{master}\n";

=head3 API SPECIFICATION

=head4 INPUT

	{
		name               => { type => 'string', min => 1, max => 64 },
		trash_days         => { type => 'integer', min => 0, optional => 1 },
		max_deletes        => { type => 'integer', min => 0, optional => 1 },
		max_delete_percent => { type => 'integer', min => 0, optional => 1 },
		ignore             => { type => 'arrayref', optional => 1 },
	}

=head4 OUTPUT

	{
		type => 'hashref',
		schema => {
			name   => { type => 'string' },
			master => { type => 'string' },
			config => { type => 'string' },
		},
	}

=head3 MESSAGES

	Key                    Meaning                       Resolution
	admin.bad_repo         the name is not a valid id    letters, digits, . _ - ; at most 64
	admin.repo_exists      the repo already exists       choose another name
	admin.root_unwritable  the root cannot be written    chown it, or use --root elsewhere
	io.mkdir / io.write    the files cannot be written   check permissions

=head3 FORMAL SPECIFICATION

	ΔFS
	pre name ∈ Id ∧ repo_config_path(root, name) ∉ dom FS ∧ writable(root)
	post repo_config_path(root, name) ∈ dom FS' ∧ index(name) = ∅

=head3 PSEUDOCODE

	validate the name; refuse if the repo exists or the root cannot be written
	start from the default policy; apply the given limits and ignore list
	create the master and metadata directories
	save the policy and an empty index

=cut

sub repo_create {
	my $self = shift;
	my $args = named(\@_, {
		name               => { type => 'string', optional => 1 },
		trash_days         => { type => 'integer', min => 0, optional => 1 },
		max_deletes        => { type => 'integer', min => 0, optional => 1 },
		max_delete_percent => { type => 'integer', min => 0, optional => 1 },
		ignore             => { type => 'arrayref', optional => 1 },
	}, 'Admin::repo_create');

	my $name = $self->_valid_repo($args->{name});

	my $config_path = App::FileSync::Config::repo_config_path($self->{root}, $name);
	$self->_throw('admin.repo_exists', { repo => $name, path => $config_path }) if -e $config_path;

	my $master = File::Spec->catdir($self->{root}, 'master', $name);
	my $meta = App::FileSync::Config::repo_meta_dir($self->{root}, $name);

	my $config = App::FileSync::Config::default_repo_config($name);
	for my $limit (qw(trash_days max_deletes max_delete_percent)) {
		$config->{$limit} = $args->{$limit} + 0 if defined $args->{$limit};
	}
	# A copy: the caller's list must not become the stored policy's storage.
	$config->{ignore} = [ @{ $args->{ignore} } ] if $args->{ignore} && @{ $args->{ignore} };

	my $made = eval {
		ensure_dir($_) for $master, map { File::Spec->catdir($meta, $_) } @META_DIRS;
		1;
	};
	unless ($made) {
		my $error = $@;
		# A root another account owns is a setup mistake.  Name the directory
		# to fix rather than the deepest one make_path could not create, which
		# is several levels below the one the administrator passed.  Only when
		# that directory really is unwritable: a full disk or a bad path keeps
		# its own error.
		my $blocked = _unwritable_base($master) // _unwritable_base($meta);
		$self->_throw('admin.root_unwritable', { root => $self->{root}, blocked => $blocked }) if defined $blocked;
		die $error;
	}

	App::FileSync::Config::save_repo($self->{root}, $name, $config);
	$self->_store($name, $config)->save_index({});

	return { name => $name, master => $master, config => $config_path };
}

=head2 repo_list

Purpose: the repos under this root.

Args: none.

Returns: an arrayref of names, sorted.

Side Effects: reads the metadata directory.

Usage:

	print "$_\n" for @{ $admin->repo_list };

=head3 EXAMPLE

	my $repos = $admin->repo_list;
	print @{$repos} ? "@{$repos}\n" : "none\n";

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'self', type => 'object' } ]

=head4 OUTPUT

	{ type => 'arrayref' }

=head3 MESSAGES

None; a root with no repos gives an empty list.

=head3 FORMAL SPECIFICATION

	repo_list = sort { n | n ∈ children(root/.filesync/repos) ∧ isdir(n) }

=cut

sub repo_list {
	my ($self) = @_;

	my $root = File::Spec->catdir($self->{root}, '.filesync', 'repos');
	return [ grep { -d File::Spec->catdir($root, $_) } @{ list_dir($root) || [] } ];
}

=head2 repo_show

Purpose: a repo's policy and where it lives.

Args: C<$name>.

Returns: C<{ config, master, meta, clients }>; C<clients> is a sorted arrayref.

Side Effects: reads the repo config.

Usage:

	my $info = $admin->repo_show('docs');

=head3 EXAMPLE

	my $info = $admin->repo_show('docs');
	print "trash kept $info->{config}{trash_days} days\n";

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'name', type => 'string', min => 1 } ]

=head4 OUTPUT

	{ type => 'hashref' }

=head3 MESSAGES

	Key              Meaning                  Resolution
	admin.bad_repo   the name is not an id    check the spelling
	config.no_repo   the repo does not exist  filesync-admin repo list

=head3 FORMAL SPECIFICATION

	repo_show(n) = ⟨config ↦ load_repo(n), master ↦ master_dir(n), meta ↦ meta_dir(n), clients ↦ sort dom config.clients⟩

=cut

sub repo_show {
	my ($self, $name) = @_;

	my $store = $self->_store($name);
	return {
		config  => $store->config,
		master  => $store->master_dir(),
		meta    => $store->meta_dir(),
		clients => [ sort keys %{ $store->config->{clients} } ],
	};
}

=head2 client_allow

Purpose: let a client (or replica) sync a repo.

Args: C<repo>, C<client> (a client id), optional C<role> (C<client>, the
default, or C<replica>).

Returns: C<{ client, role }>.

Side Effects: rewrites the repo config.  Allowing an existing client again
changes its role.

Usage:

	$admin->client_allow(repo => 'docs', client => 'backup', role => 'replica');

=head3 EXAMPLE

	$admin->client_allow(repo => 'docs', client => 'laptop');

=head3 API SPECIFICATION

=head4 INPUT

	{
		repo   => { type => 'string', min => 1 },
		client => { type => 'string', optional => 1 },
		role   => { type => 'string', optional => 1, memberof => [ 'client', 'replica' ] },
	}

=head4 OUTPUT

	{ type => 'hashref', schema => { client => { type => 'string' }, role => { type => 'string' } } }

=head3 MESSAGES

	Key               Meaning                         Resolution
	admin.bad_client  the client id is not valid      letters, digits, . _ - ; at most 64
	admin.bad_role    the role is not client/replica  choose one of those
	admin.bad_repo    the repo name is not an id      check the spelling
	config.no_repo    the repo does not exist         create it first

=head3 FORMAL SPECIFICATION

	ΔRepoConfig
	pre client ∈ Id ∧ role ∈ {client, replica}
	clients' = clients ⊕ {client ↦ role}

=cut

sub client_allow {
	my $self = shift;
	my $args = named(\@_, {
		%REPO,
		client => { type => 'string', optional => 1 },
		role   => { type => 'string', optional => 1 },
	}, 'Admin::client_allow');

	my $client = $self->_valid_client($args->{client});
	my $role = $args->{role} || $ROLE_CLIENT;
	$self->_throw('admin.bad_role', { role => $role, roles => join(', ', @ROLES) })
		unless any { $_ eq $role } @ROLES;

	my $repo = $self->_valid_repo($args->{repo});
	my $config = App::FileSync::Config::load_repo($self->{root}, $repo);
	$config->{clients}{$client} = { role => $role };
	App::FileSync::Config::save_repo($self->{root}, $repo, $config);

	return { client => $client, role => $role };
}

=head2 client_list

Purpose: the clients allowed on a repo.

Args: C<$repo>.

Returns: an arrayref, sorted by id, of C<{ client, role, base }>; C<base> is 1
when the server holds that client's base (it has synced at least once).

Side Effects: reads the repo config.

Usage:

	for my $c (@{ $admin->client_list('docs') }) { ... }

=head3 EXAMPLE

	printf "%-12s %s\n", $_->{client}, $_->{role} for @{ $admin->client_list('docs') };

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'repo', type => 'string', min => 1 } ]

=head4 OUTPUT

	{ type => 'arrayref' }

=head3 MESSAGES

	Key              Meaning                  Resolution
	config.no_repo   the repo does not exist  check the name

=head3 FORMAL SPECIFICATION

	client_list(r) = sort ⟨ (c, role(c), base(c) ∈ dom FS) | c ∈ dom clients(r) ⟩

=cut

sub client_list {
	my ($self, $repo) = @_;

	my $store = $self->_store($repo);
	my $clients = $store->config->{clients};

	# A hand-edited config may hold an id that is not one; list it without a base.
	return [
		map {
			my $entry = $clients->{$_};
			my $base = eval { $store->base_path($_) };
			{
				client => $_,
				role   => (ref($entry) eq 'HASH' && $entry->{role}) || $ROLE_CLIENT,
				base   => (defined $base && -e $base) ? 1 : 0,
			}
		} sort keys %{$clients}
	];
}

=head2 client_forget

Purpose: drop the server's base for a client, so its next sync starts afresh.

Args: C<repo>, C<client>.

Returns: C<{ removed =E<gt> 0|1, path }>.

Side Effects: removes the client's base file.  The client stays allowed.

Usage:

	$admin->client_forget(repo => 'docs', client => 'laptop');

=head3 EXAMPLE

	my $done = $admin->client_forget(repo => 'docs', client => 'old-laptop');
	print $done->{removed} ? "forgot\n" : "nothing to forget\n";

=head3 API SPECIFICATION

=head4 INPUT

	{
		repo   => { type => 'string', min => 1 },
		client => { type => 'string', min => 1 },
	}

=head4 OUTPUT

	{ type => 'hashref', schema => { removed => { type => 'integer' }, path => { type => 'string' } } }

=head3 MESSAGES

	Key               Meaning                        Resolution
	store.bad_client  the client id is not valid     check the spelling
	io.remove         the base cannot be removed     check permissions

=head3 FORMAL SPECIFICATION

	ΔFS
	FS' = {base_path(r, c)} ⩤ FS
	removed = 1 ⇔ base_path(r, c) ∈ dom FS

=cut

sub client_forget {
	my $self = shift;
	my $args = named(\@_, { %REPO, client => { type => 'string', min => 1 } }, 'Admin::client_forget');

	# base_path validates the id, so "../x" cannot reach outside the repo.
	my $path = $self->_store($args->{repo})->base_path($args->{client});
	return { removed => 0, path => $path } unless -e $path;

	eval { unlink $path; 1 } or $self->_throw('io.remove', { path => $path, error => os_error($@) });
	return { removed => 1, path => $path };
}

=head2 journal_dir

Purpose: where a repo's journal lives.

Args: C<$repo>.

Returns: F<ROOT/.filesync/repos/REPO/journal>.

Side Effects: reads the repo config.

Usage:

	my $dir = $admin->journal_dir('docs');

=head3 EXAMPLE

	print $admin->journal_dir('docs'), "\n";

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'repo', type => 'string', min => 1 } ]

=head4 OUTPUT

	{ type => 'string', min => 1 }

=head3 MESSAGES

	Key              Meaning                  Resolution
	config.no_repo   the repo does not exist  check the name

=head3 FORMAL SPECIFICATION

	journal_dir(r) = meta_dir(r) / "journal"

=cut

sub journal_dir {
	my ($self, $repo) = @_;

	return File::Spec->catdir($self->_store($repo)->meta_dir(), 'journal');
}

=head2 journal_read

Purpose: the journal's events, filtered.

Args: C<repo>; optional filters C<client> (id), C<since> and C<until>
(C<YYYY-MM-DD> or epoch, inclusive), C<exits> (arrayref of exit codes; selects
session outcomes), C<warnings> (sessions that kept conflict copies) and
C<limit> (the newest N).

Returns: an arrayref of event hashrefs, oldest first.

Side Effects: reads every monthly journal file.  A torn final line from a
killed run is skipped.

Usage:

	my $events = $admin->journal_read(repo => 'docs', since => '2026-10-01', limit => 50);

=head3 EXAMPLE

	for my $event (@{ $admin->journal_read(repo => 'docs', exits => [ 1, 2 ]) }) {
		print "$event->{ts} $event->{client} exit $event->{exit}\n";
	}

=head3 API SPECIFICATION

=head4 INPUT

	{
		repo     => { type => 'string', min => 1 },
		client   => { type => 'string', optional => 1 },
		since    => { type => 'string', optional => 1 },
		until    => { type => 'string', optional => 1 },
		exits    => { type => 'arrayref', optional => 1 },
		warnings => { type => 'boolean', optional => 1 },
		limit    => { type => 'integer', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'arrayref' }

=head3 MESSAGES

	Key            Meaning                         Resolution
	when.bad       since/until is not a date       use YYYY-MM-DD or an epoch
	io.read        a journal file cannot be read   check permissions

=head3 FORMAL SPECIFICATION

	let E = ⟨ e | f ∈ sort(journal files), line ∈ f, e = json(line) ∈ HASH ⟩
	journal_read = last limit (sort_by ts (filter(E)))

=head3 PSEUDOCODE

	read every journal file in name (month) order, skipping torn lines
	keep events for the client, inside since..until
	keep session outcomes with a wanted exit code, if asked
	keep sessions that kept conflict copies, if asked
	sort by time; keep the newest limit

=cut

sub journal_read {
	my $self = shift;
	my $args = named(\@_, {
		%REPO,
		client   => { type => 'string', optional => 1 },
		since    => { type => 'string', optional => 1 },
		until    => { type => 'string', optional => 1 },
		exits    => { type => 'arrayref', optional => 1 },
		warnings => { type => 'scalar', optional => 1 },
		limit    => { type => 'integer', optional => 1 },
	}, 'Admin::journal_read');

	# list_dir, not glob: glob splits a root containing spaces into words.
	my $dir = $self->journal_dir($args->{repo});
	my @files = map { File::Spec->catfile($dir, $_) } grep { $_ =~ $JOURNAL_FILE } @{ list_dir($dir) || [] };

	my $keep = $self->_event_filter($args);
	my @events = sort { ($a->{ts} || 0) <=> ($b->{ts} || 0) } grep { $keep->($_) } map { @{ _read_events($_) } } @files;

	my $limit = $args->{limit};
	splice(@events, 0, @events - $limit) if defined $limit && $limit > 0 && @events > $limit;
	return \@events;
}

=head2 verify

Purpose: rehash the master against its index and report what no longer
agrees.

Args: C<repo>, optional C<deep> (hash every file) and C<sample> (hash N
random files).

Returns: the L<App::FileSync::Verify> report, plus C<repo> and C<master>.

Side Effects: reads the master tree; logs a debug summary.

Usage:

	my $report = $admin->verify(repo => 'docs', deep => 1);

=head3 EXAMPLE

	my $report = $admin->verify(repo => 'docs', sample => 20);
	print $report->{ok} ? "clean\n" : "drift\n";

=head3 API SPECIFICATION

=head4 INPUT

	{
		repo   => { type => 'string', min => 1 },
		deep   => { type => 'boolean', optional => 1 },
		sample => { type => 'integer', min => 0, optional => 1 },
	}

=head4 OUTPUT

	{ type => 'hashref' }

=head3 MESSAGES

	Key              Meaning                  Resolution
	config.no_repo   the repo does not exist  check the name
	verify.*         see App::FileSync::Verify

=head3 FORMAL SPECIFICATION

	verify(r) = Verify(master_dir(r), index(r), ignore(r)) ⊕ ⟨repo ↦ r, master ↦ master_dir(r)⟩

=cut

sub verify {
	my $self = shift;
	my $args = named(\@_, {
		%REPO,
		deep   => { type => 'scalar', optional => 1 },
		sample => { type => 'integer', min => 0, optional => 1 },
	}, 'Admin::verify');

	my $repo = $args->{repo};
	my $store = $self->_store($repo);

	my $report = App::FileSync::Verify::verify(
		root    => $store->master_dir(),
		entries => $store->load_index(),
		ignore  => App::FileSync::Ignore->new(patterns => $store->config->{ignore}),
		deep    => $args->{deep},
		sample  => $args->{sample},
	);
	@{$report}{qw(repo master)} = ($repo, $store->master_dir());

	$self->{logger}->debug('verify finished', {
		repo => $repo,
		files => $report->{files},
		(map { $_ => scalar @{ $report->{$_} } } qw(modified missing extra)),
		ok => $report->{ok} ? 1 : 0,
	});

	return $report;
}

=head2 reindex

Purpose: rebuild F<master.json> from the tree, hashing every file.

Used after a manual repair (a rollback from a backup, say) so the index
describes the restored master without waiting for the next client session.
The old index is deliberately not reused: a restored file can keep its size
and mtime while its content differs, which is exactly the case reindex exists
for.

Args: C<repo>, optional C<dry_run>.

Returns: C<{ repo, master, index, files, dirs, bytes, skipped, dry_run, written }>.

Side Effects: holds the repo lock (the same one the server takes), so it never
races a session; writes the index and a journal event unless C<dry_run>.

Usage:

	my $result = $admin->reindex(repo => 'docs');

=head3 EXAMPLE

	my $plan = $admin->reindex(repo => 'docs', dry_run => 1);
	print "would index $plan->{files} files\n";

=head3 API SPECIFICATION

=head4 INPUT

	{
		repo    => { type => 'string', min => 1 },
		dry_run => { type => 'boolean', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'hashref' }

=head3 MESSAGES

	Key              Meaning                              Resolution
	admin.locked     a sync session holds the repo lock   retry when it has finished
	config.no_repo   the repo does not exist              check the name

=head3 FORMAL SPECIFICATION

	ΔFS
	pre lock(r) is free
	¬dry_run ⇒ index'(r) = scan(master_dir(r))

=head3 PSEUDOCODE

	open the repo and take its lock
	walk the master, hashing everything
	unless dry run: save the index and journal the reindex
	log and report the counts

=cut

sub reindex {
	my $self = shift;
	my $args = named(\@_, { %REPO, dry_run => { type => 'scalar', optional => 1 } }, 'Admin::reindex');

	my $repo = $args->{repo};
	my $store = $self->_store($repo);
	my $dry_run = $args->{dry_run} ? 1 : 0;

	# Held until $lock goes out of scope at the end of this method.
	my $lock = $store->acquire_lock() or $self->_throw('admin.locked', { repo => $repo });

	my ($manifest, $stats, $skipped) = @{ $store->walk_master({}) }{qw(manifest stats skipped)};
	my %counts = (map { $_ => $stats->{$_} } qw(files dirs bytes));

	unless ($dry_run) {
		$store->save_index($manifest);
		$store->journal({ action => 'reindex', %counts, skipped => scalar(keys %{$skipped}), result => 'ok' });
	}

	$self->{logger}->info('reindexed master', {
		repo => $repo, %counts, skipped => scalar(keys %{$skipped}), dry_run => $dry_run,
	});

	return {
		repo    => $repo,
		master  => $store->master_dir(),
		index   => $store->index_path(),
		%counts,
		skipped => $skipped,
		dry_run => $dry_run,
		written => $dry_run ? 0 : 1,
	};
}

=head2 restore

Purpose: put a path back from the server trash: into the master by default,
or into C<to> as an export.

Args: C<repo>, C<path> (the relative path as synced), optional C<to> (a
directory), C<date> (C<YYYY-MM-DD>; the newest version from that day), C<list>
(only list the versions).

Returns: with C<list>, C<{ repo, path, versions }> (rows from
L<App::FileSync::Trash/version_info>); otherwise
C<{ repo, path, from, to, date, sha256, into_master }>.

Side Effects: copies the version out (the trash entry is kept, so this is
repeatable); when restoring into the master, rebuilds the index so verify and
the next sync agree; journals the restore.

Usage:

	$admin->restore(repo => 'docs', path => 'notes/a.txt');

=head3 EXAMPLE

	my $done = $admin->restore(repo => 'docs', path => 'a.txt', to => '/tmp/out', date => '2026-10-20');
	print "restored to $done->{to}\n";

=head3 API SPECIFICATION

=head4 INPUT

	{
		repo => { type => 'string', min => 1 },
		path => { type => 'string', min => 1 },
		to   => { type => 'string', optional => 1 },
		date => { type => 'string', optional => 1 },
		list => { type => 'boolean', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'hashref' }

=head3 MESSAGES

	Key                  Meaning                                 Resolution
	admin.unsafe_path    the path fails validate_relpath         fix the path
	admin.no_versions    nothing of that path is in the trash    check "restore --list"
	admin.bad_date       the date is not YYYY-MM-DD              fix it
	admin.no_version_on  no version from that day                pick a listed date
	admin.not_dir        the export target is not a directory    choose another
	admin.exists         the destination exists                  move it aside first

=head3 FORMAL SPECIFICATION

	ΔFS
	pre path ∈ SafePath ∧ versions(path) ≠ ⟨⟩ ∧ dest ∉ dom FS
	post tree'(dest) = tree(chosen) ∧ (into_master ⇒ index' = scan(master))

=head3 PSEUDOCODE

	validate the path and list its trashed versions
	if listing, return them
	choose the newest version, or the newest from the given day
	destination: the master, or the export directory (created if needed)
	refuse to overwrite; copy the version out
	if into the master, rebuild the index
	journal, log and report

=cut

sub restore {
	my $self = shift;
	my $args = named(\@_, {
		%REPO,
		path => { type => 'string', optional => 1 },
		to   => { type => 'string', optional => 1 },
		date => { type => 'string', optional => 1 },
		list => { type => 'scalar', optional => 1 },
	}, 'Admin::restore');

	my ($repo, $path) = @{$args}{qw(repo path)};
	my ($safe, $reason) = validate_relpath($path);
	$self->_throw('admin.unsafe_path', { path => $path // '', reason => $reason }) unless $safe;

	my $store = $self->_store($repo);
	my $versions = App::FileSync::Trash::versions(root => $store->trash_dir(), rel => $path);

	if ($args->{list}) {
		return { repo => $repo, path => $path, versions => [ map { App::FileSync::Trash::version_info($_) } @{$versions} ] };
	}

	my $chosen = $self->_choose_version($versions, $args);

	my $into_master = !(defined $args->{to} && length $args->{to});
	my $base = $into_master ? $store->master_dir() : $args->{to};
	unless ($into_master) {
		ensure_dir($base);
		$self->_throw('admin.not_dir', { path => $base }) unless -d $base;
	}

	my $destination = File::Spec->catfile($base, split m{/}, $path);
	$self->_throw('admin.exists', { path => $destination }) if -e $destination || -l $destination;

	App::FileSync::Trash::restore(src => $chosen, to => $destination);
	my $sha = sha256_file($destination);

	# The index is a cache; rebuild it so verify and the next sync agree that
	# the restored tree is what the master now holds.
	$store->save_index($store->walk_master($store->load_index())->{manifest}) if $into_master;

	my %moved = (path => $path, to => $destination, (defined $sha ? (sha256 => $sha) : ()));
	$store->journal({ action => 'restore', %moved, trash => $chosen, result => 'ok' });
	$self->{logger}->info('restored path', { repo => $repo, path => $path, from => $chosen, to => $destination });

	return {
		repo => $repo,
		%moved,
		from => $chosen,
		date => App::FileSync::Trash::date_of($chosen),
		into_master => $into_master ? 1 : 0,
	};
}

# _unwritable_base
# Purpose:     find the nearest existing directory above a path that this
#              account cannot write.
# Entry:       $path is the file or directory about to be created.
# Exit:        returns that directory, or undef when every existing one is
#              writable (so creation should succeed).
# Side effects: none.
sub _unwritable_base :Private {
	my ($path) = @_;

	my $base = $path;
	$base = dirname($base) while !-d $base && dirname($base) ne $base;

	return (-d $base && !-w $base) ? $base : undef;
}

# _store
# Purpose:     open a repo after checking its name.
# Entry:       $repo is the caller's name; $config optional (saves a read).
# Exit:        returns an App::FileSync::Store.
# Side effects: reads the repo config unless given; raises admin.bad_repo or
#              config.no_repo.
sub _store :Private {
	my ($self, $repo, $config) = @_;

	return App::FileSync::Store->new(
		root     => $self->{root},
		repo     => $self->_valid_repo($repo),
		language => $self->{language},
		($config ? (config => $config) : ()),
	);
}

# _valid_repo / _valid_client
# Purpose:     check an id with the shared validators (which also cap the
#              length), so admin, server and transport agree on what an id is.
# Entry:       the candidate, possibly undef.
# Exit:        returns the id.
# Side effects: raises admin.bad_repo / admin.bad_client.
sub _valid_repo :Private {
	my ($self, $name) = @_;

	my ($ok, $reason) = validate_repo_name($name);
	$self->_throw('admin.bad_repo', { reason => $reason }) unless $ok;
	return $name;
}

sub _valid_client :Private {
	my ($self, $id) = @_;

	my ($ok, $reason) = validate_client_id($id);
	$self->_throw('admin.bad_client', { reason => $reason }) unless $ok;
	return $id;
}

# _event_filter
# Purpose:     turn journal_read's options into one predicate.
# Entry:       $args validated by journal_read.
# Exit:        returns a coderef taking an event, true to keep it.
# Side effects: raises when.bad for a malformed since/until (before any
#              file is read, since the bounds are parsed here).
sub _event_filter :Private {
	my ($self, $args) = @_;

	my $client = (defined $args->{client} && length $args->{client}) ? $args->{client} : undef;
	my $since = defined $args->{since} ? parse_since($args->{since}) : undef;
	my $until = defined $args->{until} ? parse_until($args->{until}) : undef;

	# Only session outcomes record an exit code, so this selects those.
	my %exits = map { ($_ + 0) => 1 } @{ $args->{exits} || [] };

	# The server journals planned conflicts on the plan event too, but only a
	# session outcome shows a run that kept the conflict copies, which is the
	# client's --warnings case.
	my $warnings = $args->{warnings};

	return sub {
		my ($event) = @_;
		my $ts = $event->{ts} || 0;
		return 0 if defined $client && !(defined $event->{client} && $event->{client} eq $client);
		return 0 if (defined $since && $ts < $since) || (defined $until && $ts > $until);
		return 0 if %exits && !(defined $event->{exit} && $exits{ $event->{exit} + 0 });
		return 0 if $warnings && !(($event->{action} || '') eq 'session' && ($event->{conflicts} || 0) > 0);
		return 1;
	};
}

# _read_events
# Purpose:     parse one journal file.
# Entry:       $file exists.
# Exit:        returns an arrayref of event hashrefs.
# Side effects: reads the file; raises io.read if it cannot be opened.
#              Lines that are not JSON objects (a torn final line from a
#              killed run) are skipped, not fatal.
sub _read_events :Private {
	my ($file) = @_;

	my $fh = open_file($file, '<');
	my @events = grep { ref($_) eq 'HASH' } map { chomp; length ? eval { json_decode($_) } : () } <$fh>;
	close $fh;

	return \@events;
}

# _choose_version
# Purpose:     pick the trashed version restore should use.
# Entry:       $versions newest first; $args has path, repo and maybe date.
# Exit:        returns a version path.
# Side effects: raises admin.no_versions, admin.bad_date or
#              admin.no_version_on.
sub _choose_version :Private {
	my ($self, $versions, $args) = @_;

	my ($repo, $path, $date) = @{$args}{qw(repo path date)};
	$self->_throw('admin.no_versions', { path => $path, repo => $repo }) unless @{$versions};
	return $versions->[0] unless defined $date && length $date;

	$self->_throw('admin.bad_date', { date => $date }) unless $date =~ $DATE;

	# date_of is undef for a path outside the dated layout; such a version
	# never matches a date.
	my ($match) = grep { (App::FileSync::Trash::date_of($_) // '') eq $date } @{$versions};
	$self->_throw('admin.no_version_on', { path => $path, date => $date }) unless defined $match;
	return $match;
}

1;

__END__

=head1 LIMITATIONS

=over 4

=item * C<journal_read> loads every monthly journal into memory before
filtering and applying C<limit>.  A repo with years of history pays for all of
it on every C<filesync-admin log>.

=item * C<restore> into the master rebuilds the index by walking the whole
tree (reusing hashes whose size and mtime match), and does not take the repo
lock: a session running at the same moment can save an index that omits the
restored file until its next sync.

=item * Admin methods take no lock except C<reindex>; C<client_allow> rewriting
the repo config while the server reads it relies on the atomic rename in
C<save_repo>.

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
