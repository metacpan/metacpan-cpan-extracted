package App::FileSync::Snapshot;

# Daily point-in-time copies of a replica's tree, kept inside the replica root
# under .filesync-snapshots/YYYY-MM-DD.  Hard links make an unchanged file
# cost nothing; copies are used where links are not possible.

use App::FileSync::Platform;

use strict;
use warnings;
use autodie qw(:all);

use File::Path qw(remove_tree);
use File::Spec;
use Readonly;
use Sub::Private { mode => 'enforce' };
use Time::HiRes ();

use App::FileSync qw(validate_relpath);
use App::FileSync::Args qw(named);
use App::FileSync::Constants qw($MODE_MASK $ROOT_MARKER $SNAPSHOT_DIR $STALE_TEMP_SECONDS $TEMP_PREFIX);
use App::FileSync::I18N qw(throw os_error);
use App::FileSync::IO qw(copy_preserving ensure_dir list_dir);

use version; our $VERSION = version->declare('0.001.5');

# Kept for compatibility: the snapshot directory's name.
our $DIR_NAME = $SNAPSHOT_DIR;

# The two ways a snapshot can hold a file.
Readonly my $HARDLINK => 'hardlink';
Readonly my $COPY     => 'copy';

# A snapshot date, and an interrupted attempt's directory.
Readonly my $DATE      => qr/\A\d{4}-\d{2}-\d{2}\z/;
Readonly my $TEMP_DIR  => qr/\A\.tmp-\d+-\d+\z/;
Readonly my $TEMP_FILE => qr/\A\Q$TEMP_PREFIX\E/;

# Windows has no POSIX permission bits worth restoring on a directory.
Readonly my $HAS_MODES => $^O ne 'MSWin32';

# Range for the random part of a temporary snapshot directory's name.
Readonly my $TEMP_RANGE => 1_000_000;

# Every function takes the replica root and needs it.
my %ROOT = (root => { type => 'string', min => 1 });

=encoding utf8

=head1 NAME

App::FileSync::Snapshot - daily snapshots of a replica

=head1 SYNOPSIS

	my $made = App::FileSync::Snapshot::create(root => $replica_root);
	my $all  = App::FileSync::Snapshot::list(root => $replica_root);
	App::FileSync::Snapshot::prune(root => $replica_root, keep => 14);
	App::FileSync::Snapshot::restore(root => $replica_root, date => '2026-10-22', to => '/tmp/out');

=head1 FUNCTIONS

=head2 snapshot_root

Purpose: where a replica keeps its snapshots.

Args: C<$root>, the replica's sync root.

Returns: F<ROOT/.filesync-snapshots>.

Side Effects: none.

Usage:

	my $dir = App::FileSync::Snapshot::snapshot_root($root);

=head3 EXAMPLE

	print App::FileSync::Snapshot::snapshot_root('/data/replica'), "\n";

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'root', type => 'string', min => 1 } ]

=head4 OUTPUT

	{ type => 'string', min => 1 }

=head3 MESSAGES

	Key                Meaning            Resolution
	snapshot.no_root   no root given      pass the replica root

=head3 FORMAL SPECIFICATION

	snapshot_root(r) = r / ".filesync-snapshots"

=cut

sub snapshot_root {
	my ($root) = @_;

	throw('snapshot.no_root') unless defined $root && length $root;
	return File::Spec->catdir($root, $SNAPSHOT_DIR);
}

=head2 date_for_epoch

Documented with L</default_mode> below.

=head2 is_date

Documented with L</default_mode> below.

=head2 default_mode

Purpose: snapshot naming and the platform's preferred storage.

Args: C<date_for_epoch($epoch)> (default now); C<is_date($string)>.

Returns: C<YYYY-MM-DD> (UTC); 1 or 0; C<hardlink>, or C<copy> on Windows.

Side Effects: none.

Usage:

	my $today = App::FileSync::Snapshot::date_for_epoch();

=head3 EXAMPLE

	print App::FileSync::Snapshot::is_date('2026-10-22'), "\n";	# 1

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'value', type => 'scalar', optional => 1 } ]

=head4 OUTPUT

	{ type => 'scalar' }

=head3 MESSAGES

None.

=head3 FORMAL SPECIFICATION

	date_for_epoch(e) = yyyy-mm-dd of gmtime(e)
	is_date(s) ⇔ s ∈ DIGIT⁴ ⁀ "-" ⁀ DIGIT² ⁀ "-" ⁀ DIGIT²
	default_mode = copy if OS = MSWin32, hardlink otherwise

=cut

sub date_for_epoch {
	my ($epoch) = @_;

	my @t = gmtime(defined $epoch ? $epoch : time);
	return sprintf('%04d-%02d-%02d', $t[5] + 1900, $t[4] + 1, $t[3]);
}

sub is_date {
	my ($date) = @_;

	return (defined $date && $date =~ $DATE) ? 1 : 0;
}

sub default_mode {
	return $^O eq 'MSWin32' ? $COPY : $HARDLINK;
}

=head2 create

Purpose: take today's snapshot of the replica tree.

Args: C<root> (required), optional C<date> (default today, from C<now>), C<now>,
C<mode> (C<hardlink> or C<copy>; default L</default_mode>).

A day is never overwritten: the first snapshot of the day is the state before
that day's first sync, which is the one worth keeping.

Returns: C<{ date, path, created, files, bytes, linked, copied, mode }>;
C<created> is 0 (and the counts 0) when that day already exists.

Side Effects: builds the snapshot in a temporary directory and renames it into
place, so an interrupted run leaves no half snapshot.  Removes interrupted
attempts older than an hour.  Hard links share storage with the live tree;
a file that cannot be linked (another filesystem) is copied.

Usage:

	my $made = App::FileSync::Snapshot::create(root => $root, mode => 'hardlink');

=head3 EXAMPLE

	my $made = App::FileSync::Snapshot::create(root => '/data/replica');
	print "$made->{files} files in $made->{path}\n" if $made->{created};

=head3 API SPECIFICATION

=head4 INPUT

	{
		root => { type => 'string', min => 1 },
		date => { type => 'string', optional => 1, matches => qr/\A\d{4}-\d{2}-\d{2}\z/ },
		now  => { type => 'number', optional => 1 },
		mode => { type => 'string', optional => 1, memberof => [ 'hardlink', 'copy' ] },
	}

=head4 OUTPUT

	{ type => 'hashref' }

=head3 MESSAGES

	Key                  Meaning                              Resolution
	snapshot.not_dir     the root is not a directory          check the replica root
	snapshot.bad_date    the date is not YYYY-MM-DD           fix the argument
	snapshot.bad_mode    the mode is not hardlink or copy     fix snapshot_mode
	snapshot.read        a directory cannot be read           check permissions
	snapshot.failed      a link, copy or rename failed        check permissions and space

=head3 FORMAL SPECIFICATION

	ΔFS
	let t = snapshot_root / date
	t ∈ dom FS ⇒ FS' = FS ∧ created = 0
	t ∉ dom FS ⇒ tree'(t) = tree(root) \ reserved ∧ created = 1

=head3 PSEUDOCODE

	if today's directory exists: report it and stop
	remove interrupted attempts older than an hour
	mirror the tree into a fresh temporary directory, linking or copying
	rename the temporary directory to the date
	on any failure remove the temporary directory and raise

=cut

sub create {
	my $args = named(\@_, {
		%ROOT,
		date => { type => 'string', optional => 1 },
		now  => { type => 'number', optional => 1 },
		mode => { type => 'string', optional => 1 },
	}, 'Snapshot::create');

	my $root = $args->{root};
	throw('snapshot.not_dir', { path => $root }) unless -d $root;

	my $date = defined $args->{date} ? $args->{date} : date_for_epoch($args->{now});
	throw('snapshot.bad_date', { date => $date }) unless is_date($date);

	my $mode = defined $args->{mode} ? $args->{mode} : default_mode();
	throw('snapshot.bad_mode', { mode => $mode }) unless $mode eq $HARDLINK || $mode eq $COPY;

	my $dir = snapshot_root($root);
	my $target = File::Spec->catdir($dir, $date);
	my %result = (date => $date, path => $target, mode => $mode);

	return { %result, created => 0, files => 0, bytes => 0 } if -e $target;

	ensure_dir($dir);
	_clean_stale_temps($dir);

	my $temp = File::Spec->catdir($dir, '.tmp-' . $$ . '-' . int(rand($TEMP_RANGE)));
	ensure_dir($temp);

	my $counts = { files => 0, bytes => 0, linked => 0, copied => 0 };
	my $ok = eval {
		_mirror($root, $temp, $mode, $counts, 1);
		rename $temp, $target;
		1;
	};

	unless ($ok) {
		my $error = $@;
		eval { remove_tree($temp) };
		# autodie's objects carry the OS reason; catalogued errors pass through.
		throw('snapshot.failed', { path => $target, error => os_error($error) }) if ref $error;
		die $error;	## no critic (ErrorHandling::RequireCarping) -- rethrow the catalogued error unchanged
	}

	return { %result, created => 1, %{$counts} };
}

=head2 list

Purpose: every snapshot, newest first.

Args: C<root>.

Returns: an arrayref of C<{ date, path, files, bytes }>.

Side Effects: walks every snapshot to count it.

Usage:

	for my $snap (@{ App::FileSync::Snapshot::list(root => $root) }) { ... }

=head3 EXAMPLE

	printf "%s %d files\n", $_->{date}, $_->{files}
		for @{ App::FileSync::Snapshot::list(root => '/data/replica') };

=head3 API SPECIFICATION

=head4 INPUT

	{ root => { type => 'string', min => 1 } }

=head4 OUTPUT

	{ type => 'arrayref' }

=head3 MESSAGES

	Key             Meaning                             Resolution
	snapshot.read   the snapshot directory is unreadable  check permissions

=head3 FORMAL SPECIFICATION

	list(r) = sort_desc(date) ⟨ (d, r/S/d, #files(r/S/d), Σ size) | d ∈ children(r/S) ∩ DATE ⟩

=cut

sub list {
	my $args = named(\@_, {%ROOT}, 'Snapshot::list');

	my $dir = snapshot_root($args->{root});
	return [] unless -d $dir;

	my $names = list_dir($dir) or throw('snapshot.read', { path => $dir, error => os_error() });
	my @dates = grep { $_ =~ $DATE && -d File::Spec->catdir($dir, $_) } @{$names};

	my @snapshots = map {
		my $path = File::Spec->catdir($dir, $_);
		my $counts = { files => 0, bytes => 0 };
		_count($path, $counts);
		{ date => $_, path => $path, %{$counts} };
	} reverse @dates;

	return \@snapshots;
}

=head2 prune

Purpose: keep the newest snapshots and remove the rest.

Args: C<root>, C<keep> (0 or undef keeps everything), C<dry_run>.

Returns: C<{ removed =E<gt> [dates], kept =E<gt> [dates] }>.

Side Effects: removes old snapshot directories unless C<dry_run>.

Usage:

	App::FileSync::Snapshot::prune(root => $root, keep => 14);

=head3 EXAMPLE

	my $plan = App::FileSync::Snapshot::prune(root => $root, keep => 7, dry_run => 1);
	print "would remove @{ $plan->{removed} }\n";

=head3 API SPECIFICATION

=head4 INPUT

	{
		root    => { type => 'string', min => 1 },
		keep    => { type => 'integer', min => 0, optional => 1 },
		dry_run => { type => 'boolean', optional => 1 },
	}

=head4 OUTPUT

	{
		type => 'hashref',
		schema => { removed => { type => 'arrayref' }, kept => { type => 'arrayref' } },
	}

=head3 MESSAGES

	Key               Meaning                        Resolution
	snapshot.remove   a snapshot cannot be removed   check permissions

=head3 FORMAL SPECIFICATION

	let s = list(root) (newest first)
	kept = s[1 .. keep] ; removed = s[keep + 1 .. #s]       if keep > 0 ∧ #s > keep
	kept = s ; removed = ⟨⟩                                otherwise

=cut

sub prune {
	my $args = named(\@_, {
		%ROOT,
		keep    => { type => 'integer', min => 0, optional => 1 },
		dry_run => { type => 'boolean', optional => 1 },
	}, 'Snapshot::prune');

	my $root = $args->{root};
	my $keep = $args->{keep};
	my @dates = map { $_->{date} } @{ list(root => $root) };

	return { removed => [], kept => \@dates } unless $keep && @dates > $keep;

	my @kept    = @dates[ 0 .. $keep - 1 ];
	my @removed = @dates[ $keep .. $#dates ];

	unless ($args->{dry_run}) {
		_remove_snapshot(File::Spec->catdir(snapshot_root($root), $_)) for @removed;
	}

	return { removed => \@removed, kept => \@kept };
}

=head2 restore

Purpose: copy a snapshot (or part of one) out.

Args: C<root>, C<date>, C<to> (the destination directory; created if
missing), optional C<paths> (relative paths inside the snapshot; default the
whole tree), C<dry_run>.

Existing destinations are replaced: this is a rollback, not a merge.

Returns: C<{ date, from, to, files, bytes, paths }>.

Side Effects: writes under C<to> unless C<dry_run>.

Usage:

	App::FileSync::Snapshot::restore(root => $root, date => $date, to => $root, paths => [ 'notes' ]);

=head3 EXAMPLE

	my $done = App::FileSync::Snapshot::restore(
		root => '/data/replica', date => '2026-10-22', to => '/tmp/export',
	);
	print "$done->{files} files restored\n";

=head3 API SPECIFICATION

=head4 INPUT

	{
		root    => { type => 'string', min => 1 },
		date    => { type => 'string', optional => 1 },
		to      => { type => 'string', optional => 1 },
		paths   => { type => 'arrayref', optional => 1 },
		dry_run => { type => 'boolean', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'hashref' }

=head3 MESSAGES

	Key                   Meaning                                Resolution
	snapshot.need_date    no date was given                      pass --date
	snapshot.bad_date     the date is not YYYY-MM-DD             fix it
	snapshot.none         no snapshot for that date              run "filesync snapshot list"
	snapshot.need_to      no destination was given               pass --to
	snapshot.to_not_dir   the destination is not a directory     choose another
	snapshot.unsafe       a path fails validate_relpath          fix the path
	snapshot.no_path      the snapshot does not hold that path   check the spelling
	snapshot.not_regular  a special file is in the snapshot      restore by hand
	snapshot.cannot_stat  a snapshot entry vanished              retry
	snapshot.replace      the destination cannot be replaced     check permissions

=head3 FORMAL SPECIFICATION

	ΔFS
	pre date ∈ dom snapshots ∧ ∀ p : paths • p ∈ SafePath ∧ p ∈ dom tree(snapshot)
	¬dry_run ⇒ ∀ p : paths • tree'(to / p) = tree(snapshot / p)

=head3 PSEUDOCODE

	check the date and that the snapshot exists
	create the destination
	paths := given paths, or every top-level entry of the snapshot
	for each path: validate it, then copy it out recursively, replacing what is there

=cut

sub restore {
	my $args = named(\@_, {
		%ROOT,
		date    => { type => 'string', optional => 1 },
		to      => { type => 'string', optional => 1 },
		paths   => { type => 'arrayref', optional => 1 },
		dry_run => { type => 'boolean', optional => 1 },
	}, 'Snapshot::restore');

	my ($root, $date, $to) = @{$args}{qw(root date to)};
	throw('snapshot.need_date') unless defined $date && length $date;
	throw('snapshot.bad_date', { date => $date }) unless is_date($date);

	my $snapshot = File::Spec->catdir(snapshot_root($root), $date);
	throw('snapshot.none', { date => $date, path => snapshot_root($root) }) unless -d $snapshot;

	throw('snapshot.need_to') unless defined $to && length $to;
	ensure_dir($to);
	throw('snapshot.to_not_dir', { path => $to }) unless -d $to;

	my @paths = @{ $args->{paths} || [] };
	@paths = @{ list_dir($snapshot) || [] } unless @paths;

	my $counts = { files => 0, bytes => 0 };
	for my $rel (@paths) {
		my ($safe, $reason) = validate_relpath($rel);
		throw('snapshot.unsafe', { path => $rel, reason => $reason }) unless $safe;

		my $from = File::Spec->catfile($snapshot, split m{/}, $rel);
		throw('snapshot.no_path', { date => $date, path => $rel }) unless -e $from || -l $from;

		_copy_out($from, File::Spec->catfile($to, split m{/}, $rel), $counts, $args->{dry_run});
	}

	return { date => $date, from => $snapshot, to => $to, %{$counts}, paths => \@paths };
}

# _mirror
# Purpose:     recreate a tree inside a snapshot, linking or copying files.
# Entry:       $dst exists; $at_root is true for the replica root itself,
#              where the reserved names live.
# Exit:        returns 1.
# Side effects: creates directories and files under $dst; updates $counts.
#              Symlinks and special files are not captured, as they are
#              not synced either.
sub _mirror :Private {
	my ($src, $dst, $mode, $counts, $at_root) = @_;

	my $names = list_dir($src) or throw('snapshot.read', { path => $src, error => os_error() });

	for my $name (@{$names}) {
		# The snapshots, the root marker and temporaries are bookkeeping, not
		# content; anything else, even a name starting ".filesync-", is data.
		next if $name eq $SNAPSHOT_DIR || $name =~ $TEMP_FILE || ($at_root && $name eq $ROOT_MARKER);

		my $from = File::Spec->catfile($src, $name);
		my $to   = File::Spec->catfile($dst, $name);
		my @stat = Time::HiRes::lstat($from) or next;

		if (-d _) {
			ensure_dir($to);
			_mirror($from, $to, $mode, $counts, 0);
			chmod($stat[2] & $MODE_MASK, $to) if $HAS_MODES;
		} elsif (-f _) {
			# A link shares the inode, so mode and mtime are already right;
			# a copy (or a failed link across filesystems) needs them set.
			my $linked = $mode eq $HARDLINK && do { no autodie qw(link); link($from, $to) };
			copy_preserving($from, $to, \@stat) unless $linked;
			$counts->{ $linked ? 'linked' : 'copied' }++;
			$counts->{files}++;
			$counts->{bytes} += $stat[7];
		}
	}

	return 1;
}

# _clean_stale_temps
# Purpose:     remove snapshot attempts that died part way.
# Entry:       $dir is the snapshot directory.
# Exit:        returns 1.
# Side effects: removes .tmp-PID-N directories older than an hour; younger
#              ones may belong to a concurrent run.
sub _clean_stale_temps :Private {
	my ($dir) = @_;

	my $now = time;
	for my $name (grep { $_ =~ $TEMP_DIR } @{ list_dir($dir) || [] }) {
		my $path = File::Spec->catdir($dir, $name);
		my @stat = Time::HiRes::lstat($path);
		next unless @stat && -d _ && $now - $stat[9] >= $STALE_TEMP_SECONDS;
		eval { remove_tree($path) };
	}

	return 1;
}

# _count
# Purpose:     count the regular files and bytes in a snapshot.
# Entry:       $dir exists.
# Exit:        returns 1.
# Side effects: adds to $counts->{files} and {bytes}.
sub _count :Private {
	my ($dir, $counts) = @_;

	for my $name (@{ list_dir($dir) || [] }) {
		my $path = File::Spec->catfile($dir, $name);
		my @stat = Time::HiRes::lstat($path) or next;
		if (-d _) {
			_count($path, $counts);
		} elsif (-f _) {
			$counts->{files}++;
			$counts->{bytes} += $stat[7];
		}
	}

	return 1;
}

# _remove_snapshot
# Purpose:     delete one snapshot directory.
# Entry:       $path is a dated snapshot.
# Exit:        returns 1.
# Side effects: removes the tree; raises snapshot.remove with the first
#              reason File::Path gave.
sub _remove_snapshot :Private {
	my ($path) = @_;

	remove_tree($path, { error => \my $errors });
	if (-e $path) {
		my ($first) = map { my ($f, $why) = %{$_}; "$f: $why" } @{ $errors || [] };
		throw('snapshot.remove', { path => $path, error => defined $first ? $first : os_error() });
	}

	return 1;
}

# _copy_out
# Purpose:     copy a snapshot entry to its destination, replacing it.
# Entry:       $src exists in the snapshot.
# Exit:        returns 1.
# Side effects: replaces $dst (unless $dry_run); updates $counts.
sub _copy_out :Private {
	my ($src, $dst, $counts, $dry_run) = @_;

	my @stat = Time::HiRes::lstat($src);
	throw('snapshot.cannot_stat', { path => $src, error => os_error() }) unless @stat;

	if (-d _) {
		ensure_dir($dst) unless $dry_run;
		_copy_out(File::Spec->catfile($src, $_), File::Spec->catfile($dst, $_), $counts, $dry_run)
			for @{ list_dir($src) || [] };

		# Directory metadata last: filling it changed its mtime.
		unless ($dry_run) {
			chmod($stat[2] & $MODE_MASK, $dst) if $HAS_MODES;
			utime($stat[9], $stat[9], $dst);
		}
		return 1;
	}

	throw('snapshot.not_regular', { path => $src }) unless -f _;
	$counts->{files}++;
	$counts->{bytes} += $stat[7];
	return 1 if $dry_run;

	# A rollback replaces whatever is in the way, even a directory.
	if (-d $dst && !-l $dst) {
		remove_tree($dst);
		throw('snapshot.replace', { path => $dst }) if -e $dst;
	} elsif (-e $dst || -l $dst) {
		eval { unlink $dst; 1 } or throw('snapshot.replace', { path => $dst });
	}

	copy_preserving($src, $dst, \@stat);
	return 1;
}

1;

__END__

=head1 LIMITATIONS

=over 4

=item * A hard-linked snapshot shares the file with the live tree.  The sync
replaces files by rename, which leaves the snapshot's link intact, but any
other tool that edits a replica file in place also changes every snapshot
that links it.  Use C<snapshot_mode copy> if anything but filesync writes
there.

=item * C<list> walks every snapshot to count it, so it is slow with many
large snapshots.

=item * Snapshots live inside the replica root, on the same disk: they guard
against bad syncs, not against losing that disk.

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
