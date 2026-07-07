#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use File::Find ();

use App::FileCleanerByDiskUage;

# Exercise the removal loop's disk-usage logic deterministically by injecting a
# fake df() (the internal _df option). The mock derives disk usage from the
# files actually left on disk, so every real unlink the loop performs is
# reflected in the next df() reading, and we can assert exactly where it stops
# and how many df() calls it took.

# build $n equal-sized files, oldest first, and return the dir + file list.
sub build {
	my ($n) = @_;
	my $dir = tempdir( CLEANUP => 1 );
	my $mtime = 1_000_000;
	my @files;
	for my $i ( 1 .. $n ) {
		my $path = File::Spec->catfile( $dir, sprintf( 'f%04d', $i ) );
		open( my $fh, '>', $path ) or die("open $path: $!");
		print {$fh} ( 'x' x 100 );
		close($fh);
		utime( $mtime, $mtime, $path );
		push( @files, $path );
		$mtime++;
	}
	return ( $dir, \@files );
}

# make a mock df over $dir whose capacity is fixed at $capacity bytes. Usage is
# the summed allocated size of the files still present, so per == percent of the
# original files remaining. Counts its own calls via $$calls_ref.
sub mock_df_for {
	my ( $dir, $capacity, $calls_ref ) = @_;
	return sub {
		$$calls_ref++;
		my $used = 0;
		File::Find::find( sub { $used += ( ( stat($_) )[12] || 0 ) * 512 if -f _ }, $dir );
		my $bavail = $capacity - $used;
		$bavail = 0 if $bavail < 0;
		return {
			per    => int( 100 * $used / $capacity + 0.5 ),
			used   => $used,
			bavail => $bavail,
		};
	};
}

# capacity = allocated size of all files, so a full directory reads as 100%.
sub capacity_of {
	my ($dir) = @_;
	my $cap = 0;
	File::Find::find( sub { $cap += ( ( stat($_) )[12] || 0 ) * 512 if -f _ }, $dir );
	return $cap;
}

# -------------------------------------------------------------------------
# stops right below the threshold, and does so with far fewer df() calls than
# files removed
# -------------------------------------------------------------------------
{
	my ( $dir, $files ) = build(100);
	my $cap = capacity_of($dir);
	my $calls = 0;
	my $df = mock_df_for( $dir, $cap, \$calls );

	my $r = App::FileCleanerByDiskUage->clean( path => $dir, du => 40, _df => $df );

	is( $r->{found_files_count}, 100, 'found all 100 files' );

	# per == remaining files, so it removes until 39 remain (removed 61).
	is( $r->{unlinked_count}, 61, 'removed exactly enough to drop below threshold' );
	is( $r->{du_ending},      39, 'du_ending reflects the real post-removal usage' );
	ok( $r->{du_ending} < 40, 'ended below the target' );

	# the 61 oldest are gone, the 39 newest remain.
	my $remaining = grep { -e $_ } @$files;
	is( $remaining, 39, '39 newest files kept on disk' );
	ok( ( !-e $files->[0] && -e $files->[-1] ), 'oldest removed, newest kept' );

	# the whole point: df() was consulted a handful of times, not ~once per
	# removed file.
	cmp_ok( $calls, '<', 10, "df() called $calls times, far fewer than 61 removals" );
}

# -------------------------------------------------------------------------
# _resync => 1 forces a df() check after every removal: same stop point, but
# many more df() calls. Confirms the resync knob works and the byte-budget path
# is what saves the calls above.
# -------------------------------------------------------------------------
{
	my ( $dir, $files ) = build(100);
	my $cap = capacity_of($dir);
	my $calls = 0;
	my $df = mock_df_for( $dir, $cap, \$calls );

	my $r = App::FileCleanerByDiskUage->clean( path => $dir, du => 40, _df => $df, _resync => 1 );

	is( $r->{unlinked_count}, 61, 'resync=1: identical stop point' );
	cmp_ok( $calls, '>=', 61, "resync=1: df() called $calls times (about once per removal)" );
}

# -------------------------------------------------------------------------
# min_files still protects the newest files even when usage stays above target
# -------------------------------------------------------------------------
{
	my ( $dir, $files ) = build(100);
	my $cap = capacity_of($dir);
	my $calls = 0;
	# capacity that keeps usage pinned at 100% no matter how much we free, so
	# only min_files can stop the loop.
	my $df = sub {
		$calls++;
		return { per => 100, used => $cap, bavail => 0 };
	};

	my $r = App::FileCleanerByDiskUage->clean( path => $dir, du => 90, min_files => 10, _df => $df );

	is( $r->{unlinked_count}, 90, 'removed all but the newest min_files' );
	my $remaining = grep { -e $_ } @$files;
	is( $remaining, 10, 'exactly min_files newest kept' );
	ok( ( -e $files->[-1] && !-e $files->[0] ), 'newest kept, oldest removed' );
}

done_testing();
