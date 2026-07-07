#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;

use App::FileCleanerByDiskUage;

# These tests avoid depending on the real disk usage percentage by using the
# two extremes:
#   du => 0   -> usage is always >= 0, so removal always triggers
#   du => 101 -> usage is always < 101, so removal never triggers
# This lets us deterministically exercise the ordering / min_files / ignore
# logic regardless of how full the underlying filesystem actually is.

# create a set of files with controlled, strictly increasing mtimes.
# returns the temp dir and an array ref of file names (oldest first).
sub make_files {
	my (@names) = @_;
	my $dir = tempdir( CLEANUP => 1 );
	my $mtime = 1_000_000;
	my @paths;
	foreach my $name (@names) {
		my $path = File::Spec->catfile( $dir, $name );
		open( my $fh, '>', $path ) or die("could not create $path: $!");
		print {$fh} "x\n";
		close($fh);
		utime( $mtime, $mtime, $path ) or die("could not utime $path: $!");
		push( @paths, $path );
		$mtime += 100;
	}
	return ( $dir, \@paths );
}

sub count_existing {
	return scalar grep { -e $_ } @_;
}

# -------------------------------------------------------------------------
# below threshold: nothing should be searched or removed
# -------------------------------------------------------------------------
{
	my ( $dir, $files ) = make_files(qw(a b c d e));
	my $r = App::FileCleanerByDiskUage->clean( path => $dir, du => 101 );

	is( $r->{unlinked_count},    0, 'below threshold: nothing unlinked' );
	is( count_existing(@$files), 5, 'below threshold: all files remain on disk' );
	is( scalar( @{ $r->{found_files} } ), 0, 'below threshold: found_files is empty (no search performed)' );
	is( $r->{du_starting}, $r->{du_ending}, 'below threshold: du_starting == du_ending' );
}

# -------------------------------------------------------------------------
# above threshold, no min_files: everything gets removed, oldest first
# -------------------------------------------------------------------------
{
	my ( $dir, $files ) = make_files(qw(a b c d e));
	my $r = App::FileCleanerByDiskUage->clean( path => $dir, du => 0 );

	is( $r->{found_files_count}, 5, 'du=0: found all five files' );
	is( $r->{unlinked_count},    5, 'du=0: all five files removed' );
	is( count_existing(@$files), 0, 'du=0: nothing left on disk' );

	# found_files must retain the full, sorted (oldest -> newest) list even
	# though the removal loop consumed everything.
	is( scalar( @{ $r->{found_files} } ), 5, 'du=0: found_files still holds all files' );
	my @found_mtimes = map { $_->{mtime} } @{ $r->{found_files} };
	is_deeply(
		\@found_mtimes,
		[ sort { $a <=> $b } @found_mtimes ],
		'du=0: found_files sorted oldest -> newest by mtime'
	);

	# unlinked list should be oldest first, matching the sorted order.
	my @unlinked_mtimes = map { $_->{mtime} } @{ $r->{unlinked} };
	is_deeply( \@unlinked_mtimes, \@found_mtimes, 'du=0: unlinked in oldest-first order' );
}

# -------------------------------------------------------------------------
# min_files keeps the newest N regardless of usage
# -------------------------------------------------------------------------
{
	my ( $dir, $files ) = make_files(qw(a b c d e));
	my $r = App::FileCleanerByDiskUage->clean( path => $dir, du => 0, min_files => 2 );

	is( $r->{min_files},      2, 'min_files: reported in results' );
	is( $r->{unlinked_count}, 3, 'min_files: removed all but the newest two' );

	# the two newest files (d, e) must survive; the three oldest must be gone.
	ok( ( !-e $files->[0] && !-e $files->[1] && !-e $files->[2] ), 'min_files: three oldest removed' );
	ok( ( -e $files->[3] && -e $files->[4] ), 'min_files: two newest kept' );

	# found_files must still contain every file that was found.
	is( scalar( @{ $r->{found_files} } ), 5, 'min_files: found_files still holds all files' );
}

# -------------------------------------------------------------------------
# fewer files than min_files: short circuit, remove nothing
# -------------------------------------------------------------------------
{
	my ( $dir, $files ) = make_files(qw(a b));
	my $r = App::FileCleanerByDiskUage->clean( path => $dir, du => 0, min_files => 5 );

	is( $r->{unlinked_count},    0, 'min_files short-circuit: nothing removed' );
	is( count_existing(@$files), 2, 'min_files short-circuit: files remain on disk' );
}

# -------------------------------------------------------------------------
# ignore regexp: matching files are neither found nor removed
# -------------------------------------------------------------------------
{
	my ( $dir, $files ) = make_files( 'a.log', 'b.keep', 'c.log', 'd.keep' );
	my $r = App::FileCleanerByDiskUage->clean( path => $dir, du => 0, ignore => '\.keep$' );

	is( $r->{found_files_count}, 2, 'ignore: only non-ignored files found' );
	is( $r->{unlinked_count},    2, 'ignore: only non-ignored files removed' );

	ok( ( -e $files->[1] && -e $files->[3] ), 'ignore: .keep files preserved' );
	ok( ( !-e $files->[0] && !-e $files->[2] ), 'ignore: .log files removed' );
}

# -------------------------------------------------------------------------
# recursion: files in subdirectories are found and removed
# -------------------------------------------------------------------------
{
	my $dir = tempdir( CLEANUP => 1 );
	my $sub = File::Spec->catdir( $dir, 'nested' );
	mkdir($sub) or die("could not mkdir $sub: $!");
	my $mtime = 1_000_000;
	my @paths;
	foreach my $spec ( [ $dir, 'top' ], [ $sub, 'deep' ] ) {
		my $path = File::Spec->catfile( @$spec );
		open( my $fh, '>', $path ) or die("could not create $path: $!");
		print {$fh} "x\n";
		close($fh);
		utime( $mtime, $mtime, $path );
		push( @paths, $path );
		$mtime += 100;
	}

	my $r = App::FileCleanerByDiskUage->clean( path => $dir, du => 0 );
	is( $r->{found_files_count}, 2, 'recursion: found file in top dir and in subdir' );
	is( count_existing(@paths),  0, 'recursion: removed files from both levels' );
}

# -------------------------------------------------------------------------
# a symlinked top-level path is followed (relies on trailing-slash handling)
# -------------------------------------------------------------------------
SKIP: {
	my ( $real, $files ) = make_files(qw(a b));
	my $link = $real . '_link';
	skip( 'symlinks not supported here', 2 ) unless eval { symlink( $real, $link ) };

	# dry_run so the underlying files survive for the existence check
	my $r = App::FileCleanerByDiskUage->clean( path => $link, du => 0, dry_run => 1 );
	is( $r->{found_files_count}, 2, 'symlinked top path: files found through the symlink' );
	is( count_existing(@$files), 2, 'symlinked top path: dry run left files intact' );

	unlink($link);
}

# -------------------------------------------------------------------------
# missing paths are recorded, a valid path in the same call still works
# -------------------------------------------------------------------------
{
	my ( $dir, $files ) = make_files(qw(a b));
	my $missing = File::Spec->catdir( $dir, 'does_not_exist' );
	my $r = App::FileCleanerByDiskUage->clean( path => [ $dir, $missing ], du => 101 );

	is( scalar( @{ $r->{missing_paths} } ), 1, 'missing path recorded' );
	is( scalar( @{ $r->{path} } ),          1, 'valid path retained' );
}

# -------------------------------------------------------------------------
# dry_run: report what would be removed but leave everything on disk
# -------------------------------------------------------------------------
{
	my ( $dir, $files ) = make_files(qw(a b c));
	my $r = App::FileCleanerByDiskUage->clean( path => $dir, du => 0, dry_run => 1 );

	is( $r->{dry_run},           1, 'dry_run: flagged in results' );
	is( $r->{unlinked_count},    3, 'dry_run: reports all three as would-be removed' );
	is( count_existing(@$files), 3, 'dry_run: nothing actually removed from disk' );
}

# a non-writable file in a dry run is reported as a failure, not a removal.
# skipped when running as root, where -w is effectively always true.
SKIP: {
	skip( 'writability check is unreliable when running as root', 2 ) if $> == 0;

	my ( $dir, $files ) = make_files(qw(a));
	chmod( 0400, $files->[0] );
	skip( 'could not make file non-writable', 2 ) if -w $files->[0];

	my $r = App::FileCleanerByDiskUage->clean( path => $dir, du => 0, dry_run => 1 );

	is( $r->{unlink_failed_count}, 1, 'dry_run: non-writable file recorded as failure' );
	is( count_existing(@$files),   1, 'dry_run: non-writable file left on disk' );

	chmod( 0600, $files->[0] );    # so File::Temp can clean up
}

# -------------------------------------------------------------------------
# input validation dies
# -------------------------------------------------------------------------
eval { App::FileCleanerByDiskUage->clean( du => 0 ); };
ok( $@, 'dies when path is undef' );

eval { App::FileCleanerByDiskUage->clean( path => tempdir( CLEANUP => 1 ) ); };
ok( $@, 'dies when du is undef' );

eval { App::FileCleanerByDiskUage->clean( path => tempdir( CLEANUP => 1 ), du => 'abc' ); };
ok( $@, 'dies when du is non-numeric' );

eval { App::FileCleanerByDiskUage->clean( path => tempdir( CLEANUP => 1 ), du => 0, min_files => 'abc' ); };
ok( $@, 'dies when min_files is non-numeric' );

done_testing();
