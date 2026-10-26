package App::FileSync::Scan;

# Walk a tree and describe it: one manifest entry per regular file (with its
# SHA-256) and per empty directory.  A previous manifest serves as a cache, so
# a file whose size and mtime are unchanged is not read again.

use App::FileSync::Platform;

use strict;
use warnings;
use autodie qw(:all);

use Digest::SHA ();
use File::Spec;
use Readonly;
use Sub::Private { mode => 'enforce' };
use Time::HiRes ();

use App::FileSync::Args qw(named);
use App::FileSync::Constants qw($MODE_MASK $TEMP_PREFIX $STALE_TEMP_SECONDS $TYPE_FILE $TYPE_DIR);
use App::FileSync::I18N qw(message os_error);
use App::FileSync::IO qw(list_dir);

use version; our $VERSION = version->declare('0.001.5');

# A cached mtime within this much of the file's is the same mtime: JSON
# round-trips the fractional part with float noise.
Readonly my $MTIME_EPSILON => 0.001;

# Matches a temporary file left by an interrupted run.
Readonly my $TEMP_NAME => qr/\A\Q$TEMP_PREFIX\E/;

# Describe one regular file, reusing the cached hash when size and mtime
# match.  Lexical rather than a named private sub because it runs once per
# file in the tree; see App::FileSync/LIMITATIONS.
#
# Entry: $context is the scan state; $abs/$rel name the file; $stat is lstat.
# Exit:  returns the manifest entry, or undef after recording the file as
#        skipped (it could not be read).
my $file_entry = sub {
	my ($context, $abs, $rel, $stat) = @_;

	my ($size, $mtime) = @{$stat}[7, 9];
	my $cached = $context->{cache}{$rel};

	my $hash;
	if ($cached
		&& ($cached->{t} || '') eq $TYPE_FILE
		&& defined $cached->{h}
		&& defined $cached->{s} && $cached->{s} == $size
		&& abs((defined $cached->{m} ? $cached->{m} : -1) - $mtime) < $MTIME_EPSILON) {
		$hash = $cached->{h};
		$context->{stats}{cached}++;
	} else {
		my $sha = Digest::SHA->new(256);
		unless (eval { $sha->addfile($abs, 'b'); 1 }) {
			$context->{skipped}{$rel} = message('scan.unreadable', { error => $@ =~ s/\s+\z//r });
			$context->{stats}{skipped}++;
			return undef;	## no critic (Subroutines::ProhibitExplicitReturnUndef)
		}
		$hash = $sha->hexdigest;
		$context->{stats}{hashed}++;
	}

	return {
		t    => $TYPE_FILE,
		s    => $size,
		m    => $mtime,
		h    => $hash,
		mode => $stat->[2] & $MODE_MASK,
	};
};

=encoding utf8

=head1 NAME

App::FileSync::Scan - describe a directory tree as a manifest

=head1 SYNOPSIS

	my $scan = App::FileSync::Scan::scan(root => $root, ignore => $ignore, cache => $last);
	for my $path (sort keys %{ $scan->{manifest} }) { ... }
	printf "%d hashed, %d reused\n", @{ $scan->{stats} }{qw(hashed cached)};

=head1 FUNCTIONS

=head2 scan

Purpose: walk a tree and describe every regular file and empty directory.

Args: C<root> (required), C<ignore> (an L<App::FileSync::Ignore>), C<cache>
(a previous manifest whose entries are reused when size and mtime still match).

Returns: a hashref with three hashrefs:

	manifest  path => { t => 'f', s => size, m => mtime, h => sha256, mode => bits }
	          path => { t => 'd' }    (only directories empty after ignores)
	stats     { files, dirs, bytes, hashed, cached, skipped }
	skipped   path => reason, for symlinks, special files and unreadable entries

Side Effects: reads every file that is not cached.  Never writes.

Usage:

	my $scan = App::FileSync::Scan::scan(root => $master, ignore => $ignore);

=head3 EXAMPLE

	my $scan = App::FileSync::Scan::scan(root => '/home/foo/Documents');
	print scalar(keys %{ $scan->{manifest} }), " entries\n";

=head3 API SPECIFICATION

=head4 INPUT

	{
		root   => { type => 'string', min => 1 },
		ignore => { type => 'object', can => 'match', optional => 1 },
		cache  => { type => 'hashref', optional => 1 },
	}

=head4 OUTPUT

	{
		type => 'hashref',
		schema => {
			manifest => { type => 'hashref' },
			stats    => { type => 'hashref' },
			skipped  => { type => 'hashref' },
		},
	}

=head3 MESSAGES

Skip reasons (in C<skipped>, not raised):

	Key                 Meaning
	scan.unreadable     a file could not be read
	scan.cannot_stat    an entry vanished or cannot be examined
	scan.cannot_list    a directory cannot be read
	scan.symlink        symbolic links are not synced
	scan.special        devices, sockets and fifos are not synced

	Key            Meaning               Resolution
	args.invalid   no root was given     pass root

=head3 FORMAL SPECIFICATION

	Manifest == PATH ⇸ ENTRY
	scan(r, ign, c) = (M, S, K) where
		dom M = { p | p ∈ files(r) ∪ emptydirs(r) ∧ ¬ ign(p) ∧ ¬ unreadable(p) }
		∀ p ∈ dom M • kind p = file ⇒ M(p).h = sha256(FS(r/p))
		dom K ∩ dom M = ∅

=head3 PSEUDOCODE

	for each entry under root, depth first, sorted:
		skip ignored paths (and everything below an ignored directory)
		directory: recurse; record it only if nothing inside was recorded
		regular file: reuse the cached hash if size and mtime match, else hash it
		anything else: record why it was skipped

=cut

sub scan {
	my $args = named(\@_, {
		root   => { type => 'string', min => 1 },
		ignore => { type => 'object', optional => 1 },
		cache  => { type => 'hashref', optional => 1 },
	}, 'Scan::scan');

	my $context = {
		ignore   => $args->{ignore},
		cache    => $args->{cache} || {},
		manifest => {},
		skipped  => {},
		stats    => { map { $_ => 0 } qw(files dirs bytes hashed cached skipped) },
	};

	_walk($context, $args->{root}, '');

	return {
		manifest => $context->{manifest},
		stats    => $context->{stats},
		skipped  => $context->{skipped},
	};
}

=head2 clean_stale_temps

Purpose: remove temporary files left behind by an interrupted run.

Args: C<root>, optional C<max_age> in seconds (default 3600).

Returns: the number of files removed.

Side Effects: deletes C<.filesync-tmp-*> files older than C<max_age> anywhere
under C<root>.  Younger ones may belong to a run in progress and are left
alone.  A file that cannot be removed is skipped.

Usage:

	App::FileSync::Scan::clean_stale_temps(root => $root);

=head3 EXAMPLE

	my $removed = App::FileSync::Scan::clean_stale_temps(root => '/srv/filesync/master/docs', max_age => 600);

=head3 API SPECIFICATION

=head4 INPUT

	{
		root    => { type => 'string', optional => 1 },
		max_age => { type => 'integer', min => 0, optional => 1 },
	}

=head4 OUTPUT

	{ type => 'integer', min => 0 }

=head3 MESSAGES

None; failures to remove are not errors.

=head3 FORMAL SPECIFICATION

	ΔFS
	Stale == { p : dom FS | p under root ∧ prefix(TEMP, basename p) ∧ now − mtime p ≥ age }
	dom FS' = dom FS \ Removable(Stale)
	result = #(dom FS \ dom FS')

=cut

sub clean_stale_temps {
	my $args = named(\@_, {
		root    => { type => 'string', optional => 1 },
		max_age => { type => 'integer', min => 0, optional => 1 },
	}, 'Scan::clean_stale_temps');

	my $root = $args->{root};
	return 0 unless defined $root && length $root && -d $root;

	my $max_age = defined $args->{max_age} ? $args->{max_age} : $STALE_TEMP_SECONDS;
	my $now = time;
	my $removed = 0;

	# Breadth first with an explicit queue: no recursion depth limit, and
	# symlinked directories are never followed because lstat says what they are.
	my @queue = ($root);
	while (@queue) {
		my $dir = shift @queue;
		for my $name (@{ list_dir($dir) || [] }) {
			my $path = File::Spec->catfile($dir, $name);
			my @stat = Time::HiRes::lstat($path) or next;
			if (-d _) {
				push @queue, $path;
			} elsif ($name =~ $TEMP_NAME && $now - $stat[9] >= $max_age) {
				no autodie qw(unlink);
				$removed++ if unlink $path;
			}
		}
	}

	return $removed;
}

# _walk
# Purpose:     scan one directory, recursing into subdirectories.
# Entry:       $context is the scan state; $abs/$rel name the directory
#              ($rel is '' at the root).
# Exit:        returns how many entries inside were recorded, so the caller
#              knows whether to record this directory as empty.
# Side effects: fills $context->{manifest}, {skipped} and {stats}.
sub _walk :Private {
	my ($context, $abs, $rel) = @_;

	my $names = list_dir($abs);
	unless ($names) {
		_skip($context, length $rel ? $rel : '.', 'scan.cannot_list', os_error());
		return 0;
	}

	my $entries = 0;
	for my $name (@{$names}) {
		my $child_rel = length $rel ? "$rel/$name" : $name;
		next if $context->{ignore} && $context->{ignore}->match($child_rel);

		my $child_abs = File::Spec->catfile($abs, $name);
		my @stat = Time::HiRes::lstat($child_abs);
		if (!@stat) {
			_skip($context, $child_rel, 'scan.cannot_stat', os_error());
		} elsif (-d _) {
			# An empty directory is worth syncing; a non-empty one is implied
			# by the files inside it.
			$entries++;
			if (_walk($context, $child_abs, $child_rel) == 0) {
				$context->{manifest}{$child_rel} = { t => $TYPE_DIR };
				$context->{stats}{dirs}++;
			}
		} elsif (-f _) {
			my $entry = $file_entry->($context, $child_abs, $child_rel, \@stat) or next;
			$context->{manifest}{$child_rel} = $entry;
			$context->{stats}{files}++;
			$context->{stats}{bytes} += $entry->{s};
			$entries++;
		} else {
			_skip($context, $child_rel, -l _ ? 'scan.symlink' : 'scan.special');
		}
	}

	return $entries;
}

# _skip
# Purpose:     record a path the manifest leaves out, and why.
# Entry:       $key names the reason in the catalogue; $error is the OS
#              reason where there is one.
# Exit:        returns 1.
# Side effects: updates $context->{skipped} and the skipped count.
sub _skip :Private {
	my ($context, $rel, $key, $error) = @_;

	$context->{skipped}{$rel} = message($key, { error => $error });
	$context->{stats}{skipped}++;
	return 1;
}

1;

__END__

=head1 LIMITATIONS

=over 4

=item * The cache trusts size and mtime.  A tool that rewrites a file and
restores its mtime (some backup restorers do) goes unnoticed until a
C<verify --deep>.

=item * Every run stats every file; there is no change notification.  On a
very large tree the walk, not the transfer, dominates a quiet run.

=item * Directory order is sorted, which costs an O(n log n) per directory
but makes manifests and logs reproducible.

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
