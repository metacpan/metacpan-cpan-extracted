package App::FileSync::Trash;

# Deleted files are never unlinked: they move into a dated trash tree
# (ROOT/YYYY/MM/DD/<relative path>) and are pruned a whole day at a time once
# they are older than the retention period.

use App::FileSync::Platform;

use strict;
use warnings;
use autodie qw(:all);

use File::Basename qw(basename dirname);
use File::Copy ();
use File::Path qw(remove_tree);
use File::Spec;
use Readonly;
use Sub::Private { mode => 'enforce' };
use Time::HiRes ();
use Time::Local ();

use App::FileSync::Args qw(named);
use App::FileSync::Constants qw($MODE_MASK $TRASH_DAYS $SECONDS_PER_DAY);
use App::FileSync::I18N qw(throw os_error);
use App::FileSync::IO qw(copy_preserving ensure_dir list_dir);

use version; our $VERSION = version->declare('0.001.2');

# The three levels of a day bucket.
Readonly my $YEAR  => qr/\A\d{4}\z/;
Readonly my $MONTH => qr/\A\d{2}\z/;
Readonly my $DAY   => qr/\A\d{2}\z/;

# Windows has no POSIX permission bits worth restoring on a directory.
Readonly my $HAS_MODES => $^O ne 'MSWin32';

=encoding utf8

=head1 NAME

App::FileSync::Trash - dated trash with retention

=head1 SYNOPSIS

	my $where = App::FileSync::Trash::move_to_trash(
		src => $abs, rel => 'notes/a.txt', root => $trash_dir,
	);
	my $versions = App::FileSync::Trash::versions(root => $trash_dir, rel => 'notes/a.txt');
	App::FileSync::Trash::restore(src => $versions->[0], to => $abs);
	App::FileSync::Trash::prune(root => $trash_dir, days => 30);

=head1 FUNCTIONS

=head2 move_to_trash

Purpose: move a file or directory into today's trash bucket.

Args: C<src> (absolute path), C<rel> (its relative path, kept inside the
bucket), C<root> (the trash directory), optional C<epoch> (default now).

Returns: the absolute path it was moved to.  A second deletion of the same
path on the same day is kept as C<PATH.1>, then C<PATH.2>, and so on.

Side Effects: renames C<src>; across filesystems a file is copied (keeping its
mtime) and the original removed.

Usage:

	my $where = App::FileSync::Trash::move_to_trash(src => $abs, rel => $rel, root => $trash);

=head3 EXAMPLE

	App::FileSync::Trash::move_to_trash(
		src => '/home/foo/Documents/old.txt', rel => 'old.txt',
		root => '/home/foo/.filesync/trash/documents', epoch => time,
	);

=head3 API SPECIFICATION

=head4 INPUT

	{
		src   => { type => 'string', min => 1 },
		rel   => { type => 'string', min => 1 },
		root  => { type => 'string', min => 1 },
		epoch => { type => 'number', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'string', min => 1 }

=head3 MESSAGES

	Key           Meaning                                   Resolution
	trash.move    the entry could not be moved              check permissions
	io.mkdir      the bucket could not be created           check permissions

=head3 FORMAL SPECIFICATION

	ΔFS
	src?, rel?, root? : PATH ; t? : ℕ ; dst! : PATH
	let b = root? / day(t?) / rel?
	dst! = b if b ∉ dom FS, else b ⁀ "." ⁀ min { n : ℕ₁ | b ⁀ "." ⁀ n ∉ dom FS }
	FS'(dst!) = FS(src?) ∧ src? ∉ dom FS'

=cut

sub move_to_trash {
	my $args = named(\@_, {
		src   => { type => 'string', min => 1 },
		rel   => { type => 'string', min => 1 },
		root  => { type => 'string', min => 1 },
		epoch => { type => 'number', optional => 1 },
	}, 'Trash::move_to_trash');

	my $src = $args->{src};
	my $epoch = defined $args->{epoch} ? $args->{epoch} : time;

	my $destination = File::Spec->catfile(_bucket($args->{root}, $epoch), split m{/}, $args->{rel});
	ensure_dir(dirname($destination));

	# Two deletions of the same path on the same day keep both.
	my $final = $destination;
	my $suffix = 0;
	$final = $destination . '.' . ++$suffix while -e $final || -l $final;

	# File::Copy::move renames when it can and otherwise copies (keeping the
	# mtime) and unlinks; a directory has to rename in one step.
	local $@;
	my $moved = -d $src && !-l $src
		? eval { rename $src, $final; 1 }
		: File::Copy::move($src, $final);
	throw('trash.move', { from => $src, to => $final, error => os_error($@) }) unless $moved;

	return $final;
}

=head2 prune

Purpose: remove day buckets older than the retention period.

Args: C<root>, optional C<days> (default 30; 0 or less disables pruning),
C<now> (default the current time), C<dry_run>.

Returns: an arrayref of the bucket directories removed (or that would be).

Side Effects: removes whole day directories.  A bucket that cannot be removed
is left and not reported.

Usage:

	my $removed = App::FileSync::Trash::prune(root => $trash, days => 30);

=head3 EXAMPLE

	my $would = App::FileSync::Trash::prune(root => $trash, days => 7, dry_run => 1);
	print "$_\n" for @{$would};

=head3 API SPECIFICATION

=head4 INPUT

	{
		root    => { type => 'string', optional => 1 },
		days    => { type => 'number', optional => 1 },
		now     => { type => 'number', optional => 1 },
		dry_run => { type => 'boolean', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'arrayref' }

=head3 MESSAGES

None.

=head3 FORMAL SPECIFICATION

	ΔFS
	Old == { b : buckets(root) | midnight(b) ≤ now − days × 86400 }
	dry_run ⇒ FS' = FS ∧ result = Old
	¬dry_run ⇒ result ⊆ Old ∧ ∀ b : result • b ∉ dom FS'

=cut

sub prune {
	my $args = named(\@_, {
		root    => { type => 'string', optional => 1 },
		days    => { type => 'number', optional => 1 },
		now     => { type => 'number', optional => 1 },
		dry_run => { type => 'boolean', optional => 1 },
	}, 'Trash::prune');

	my $root = $args->{root};
	my $days = defined $args->{days} ? $args->{days} : $TRASH_DAYS;
	return [] unless defined $root && length $root && -d $root && $days > 0;

	my $cutoff = (defined $args->{now} ? $args->{now} : time) - $days * $SECONDS_PER_DAY;

	my @removed;
	for my $bucket (@{ _buckets($root) }) {
		# Compare whole days so a mid-day run does not prune a bucket that
		# only just crossed the boundary.
		next if _midnight_epoch(@{$bucket}{qw(year month day)}) > $cutoff;

		my $gone = $args->{dry_run} || remove_tree($bucket->{path}, { error => \my $errors });
		push @removed, $bucket->{path} if $gone;
	}

	return \@removed;
}

=head2 versions

Purpose: every stored version of a path.

Args: C<root>, C<rel>.

Returns: an arrayref of absolute paths, newest first: by day, then by the
same-day suffix (C<.2> before C<.1> before the unsuffixed first deletion).

Side Effects: none.

Usage:

	my $versions = App::FileSync::Trash::versions(root => $trash, rel => 'notes/a.txt');

=head3 EXAMPLE

	my ($newest) = @{ App::FileSync::Trash::versions(root => $trash, rel => 'a.txt') };

=head3 API SPECIFICATION

=head4 INPUT

	{
		root => { type => 'string', optional => 1 },
		rel  => { type => 'string', min => 1 },
	}

=head4 OUTPUT

	{ type => 'arrayref' }

=head3 MESSAGES

	Key            Meaning              Resolution
	args.invalid   no rel was given     pass the path

=head3 FORMAL SPECIFICATION

	versions(root, rel) = sort_desc(day, suffix)
		{ v | ∃ b : buckets(root) • v = b/rel ∨ ∃ n : ℕ₁ • v = b/rel ⁀ "." ⁀ n }

=cut

sub versions {
	my $args = named(\@_, {
		root => { type => 'string', optional => 1 },
		rel  => { type => 'string', min => 1 },
	}, 'Trash::versions');

	my $root = $args->{root};
	return [] unless defined $root && -d $root;

	my @parts = split m{/}, $args->{rel};
	my $name = pop @parts;
	my $stored = qr/\A\Q$name\E(?:\.(\d+))?\z/;

	# Collect [ path, date, suffix ] so the order is numeric: a plain string
	# sort would put "a.txt.10" before "a.txt.9".
	my @found;
	for my $bucket (@{ _buckets($root) }) {
		my $dir = File::Spec->catdir($bucket->{path}, @parts);
		for my $entry (@{ list_dir($dir) || [] }) {
			next unless $entry =~ $stored;
			push @found, [ File::Spec->catfile($dir, $entry), $bucket->{date}, defined $1 ? $1 : 0 ];
		}
	}

	my @newest_first = sort { $b->[1] cmp $a->[1] || $b->[2] <=> $a->[2] } @found;
	return [ map { $_->[0] } @newest_first ];
}

=head2 restore

Purpose: copy one trashed version out, keeping modes and mtimes.

Args: C<src> (a path from L</versions>), C<to> (the destination; must not exist).

Returns: C<to>.

Side Effects: copies a file, or a directory tree, to C<to>.  The trash entry is
left in place, so the same version can be restored twice.

Usage:

	App::FileSync::Trash::restore(src => $versions->[0], to => $abs);

=head3 EXAMPLE

	App::FileSync::Trash::restore(src => $version, to => '/tmp/recovered.txt');

=head3 API SPECIFICATION

=head4 INPUT

	{
		src => { type => 'string', min => 1 },
		to  => { type => 'string', min => 1 },
	}

=head4 OUTPUT

	{ type => 'string', min => 1 }

=head3 MESSAGES

	Key                  Meaning                              Resolution
	trash.missing        the version is not there             list versions again
	trash.exists         the destination already exists       move it aside
	trash.cannot_stat    an entry cannot be examined          check permissions
	trash.not_regular    a special file is in the version     restore by hand
	io.copy              a file could not be copied           check space

=head3 FORMAL SPECIFICATION

	ΔFS
	pre src ∈ dom FS ∧ to ∉ dom FS
	post tree'(to) = tree(src) ∧ src ∈ dom FS'

=cut

sub restore {
	my $args = named(\@_, {
		src => { type => 'string', min => 1 },
		to  => { type => 'string', min => 1 },
	}, 'Trash::restore');
	my ($src, $to) = @{$args}{qw(src to)};

	throw('trash.missing', { path => $src }) unless -e $src || -l $src;
	throw('trash.exists', { path => $to }) if -e $to || -l $to;

	_restore_entry($src, $to);
	return $to;
}

=head2 date_of

Purpose: the trash day a stored path belongs to.

Args: C<$path>, as returned by L</versions> or L</move_to_trash>.

Returns: C<YYYY-MM-DD>, or C<undef> for a path outside a day bucket.  Both
C</> and C<\> separators are understood.

Side Effects: none.

Usage:

	my $date = App::FileSync::Trash::date_of($version);

=head3 EXAMPLE

	print App::FileSync::Trash::date_of('/t/trash/2026/10/22/a/b.txt'), "\n";	# 2026-10-22

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'path', type => 'string', optional => 1 } ]

=head4 OUTPUT

	{ type => 'string', optional => 1, matches => qr/\A\d{4}-\d{2}-\d{2}\z/ }

=head3 MESSAGES

None.

=head3 FORMAL SPECIFICATION

	date_of(p ⁀ sep ⁀ yyyy ⁀ sep ⁀ mm ⁀ sep ⁀ dd ⁀ sep ⁀ q) = yyyy ⁀ "-" ⁀ mm ⁀ "-" ⁀ dd

=cut

sub date_of {
	my ($path) = @_;

	my @date = defined $path ? $path =~ m{[/\\](\d{4})[/\\](\d{2})[/\\](\d{2})[/\\]} : ();
	return @date ? join('-', @date) : undef;
}

=head2 version_info

Purpose: describe one trashed version for a listing.

Args: C<$path>, a path from L</versions>.

Returns: C<{ path, date, size, mtime }>; C<size> and C<mtime> are C<undef> if
the version has gone since it was listed.

Side Effects: stats the path.

Usage:

	my @rows = map { App::FileSync::Trash::version_info($_) } @{$versions};

=head3 EXAMPLE

	my $info = App::FileSync::Trash::version_info($versions->[0]);
	print "$info->{date} $info->{size} bytes\n";

=head3 API SPECIFICATION

=head4 INPUT

	[ { name => 'path', type => 'string', min => 1 } ]

=head4 OUTPUT

	{
		type => 'hashref',
		schema => {
			path  => { type => 'string' },
			date  => { type => 'string', optional => 1 },
			size  => { type => 'integer', optional => 1 },
			mtime => { type => 'number', optional => 1 },
		},
	}

=head3 MESSAGES

None.

=head3 FORMAL SPECIFICATION

	version_info(p) = ⟨path ↦ p, date ↦ date_of(p), size ↦ size(FS(p)), mtime ↦ mtime(FS(p))⟩

=cut

sub version_info {
	my ($path) = @_;

	# A listing races with prune, so a vanished version is reported, not fatal.
	my @stat = Time::HiRes::stat($path);
	return {
		path  => $path,
		date  => date_of($path),
		size  => @stat ? $stat[7] : undef,
		mtime => @stat ? $stat[9] : undef,
	};
}

# _bucket
# Purpose:     the day directory for an epoch.
# Entry:       $root is the trash root; $epoch a time.
# Exit:        returns ROOT/YYYY/MM/DD (UTC).
# Side effects: none.
sub _bucket :Private {
	my ($root, $epoch) = @_;

	my @t = gmtime($epoch);
	return File::Spec->catdir($root,
		sprintf('%04d', $t[5] + 1900), sprintf('%02d', $t[4] + 1), sprintf('%02d', $t[3]));
}

# _buckets
# Purpose:     every day bucket under a trash root.
# Entry:       $root exists.
# Exit:        returns an arrayref of { path, year, month, day, date },
#              oldest first.
# Side effects: none.  Stray names at any level are ignored.
sub _buckets :Private {
	my ($root) = @_;

	my @buckets;
	for my $year (grep { $_ =~ $YEAR } @{ list_dir($root) || [] }) {
		my $year_dir = File::Spec->catdir($root, $year);
		for my $month (grep { $_ =~ $MONTH } @{ list_dir($year_dir) || [] }) {
			my $month_dir = File::Spec->catdir($year_dir, $month);
			for my $day (grep { $_ =~ $DAY } @{ list_dir($month_dir) || [] }) {
				push @buckets, {
					path  => File::Spec->catdir($month_dir, $day),
					year  => $year,
					month => $month,
					day   => $day,
					date  => "$year-$month-$day",
				};
			}
		}
	}

	return \@buckets;
}

# _restore_entry
# Purpose:     copy a trashed file or directory tree out of the trash.
# Entry:       $src exists; $to does not (or is a directory being filled).
# Exit:        returns 1.
# Side effects: creates $to; raises trash.cannot_stat or trash.not_regular.
sub _restore_entry :Private {
	my ($src, $to) = @_;

	my @stat = Time::HiRes::lstat($src);
	throw('trash.cannot_stat', { path => $src, error => os_error() }) unless @stat;

	if (-d _) {
		ensure_dir($to);
		_restore_entry(File::Spec->catfile($src, $_), File::Spec->catfile($to, $_))
			for @{ list_dir($src) || [] };

		# Directory metadata last: filling it changed its mtime.
		chmod($stat[2] & $MODE_MASK, $to) if $HAS_MODES;
		utime($stat[9], $stat[9], $to);
		return 1;
	}

	throw('trash.not_regular', { path => $src }) unless -f _;
	copy_preserving($src, $to, \@stat);

	return 1;
}

# _midnight_epoch
# Purpose:     the UTC epoch at the start of a bucket's day.
# Entry:       numeric year, month (1-12) and day strings from a bucket path.
# Exit:        returns the epoch.
# Side effects: none.
sub _midnight_epoch :Private {
	my ($year, $month, $day) = @_;

	return Time::Local::timegm(0, 0, 0, $day, $month - 1, $year);
}

1;

__END__

=head1 LIMITATIONS

=over 4

=item * A same-day collision is stored as C<PATH.N>.  A real file whose name
already ends in C<.N> (C<backup.1>) deleted the same day as C<backup> is
therefore listed as a version of C<backup> too.

=item * Moving a directory across filesystems is not supported; files are
copied and removed, directories must rename.

=item * Pruning works in whole UTC days, so retention is accurate to a day.

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
