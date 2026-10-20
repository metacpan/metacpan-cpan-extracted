use v5.40;
use blib;
use Test2::V0 '!subtest', -no_srand => 1;
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use Path::Tiny qw[path];
use File::Temp qw[tempdir];
use Alien::Xrepo::Build::Dist;
use Config;
use experimental 'class';
#
my $tmp = Path::Tiny->tempdir;
#
# Set up mock package
$tmp->child('Build.PL')->spew("1;\n");
my $mod_dir = $tmp->child( 'lib', 'Alien' );
$mod_dir->mkpath;
$mod_dir->child('Sample.pm')->spew(<<'PM');
package Alien::Sample;
use v5.40;
sub new { bless {}, shift }
sub recipe { { packages => ['zlib'] } }
1;
PM
my $dist = Alien::Xrepo::Build::Dist->new( base_dir => $tmp->stringify, module_name => 'Alien::Sample', script => 'Build.PL' );
is $dist->dist_name,  'Alien-Sample',    'dist_name converts :: to -';
is $dist->module_rel, 'Alien/Sample.pm', 'module_rel calculates relative path';
ok -f $dist->module_path, 'module_path exists';

# Test snapshot staleness
my $snap_file = path( $dist->snapshot_path );
ok $dist->snapshot_stale( $snap_file->stringify ), 'Snapshot is stale when absent';

# Create fresh snapshot
$snap_file->parent->mkpath;
$snap_file->spew("{}");

# Ensure mtime is newer than inputs
utime time + 10, time + 10, $snap_file->stringify;
ok !$dist->snapshot_stale( $snap_file->stringify ), 'Snapshot is fresh when newer than inputs';

# Update input file mtime
utime time + 20, time + 20, $dist->module_path;
ok $dist->snapshot_stale( $snap_file->stringify ), 'Snapshot is stale after module updated';
#
done_testing;
