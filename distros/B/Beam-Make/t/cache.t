
use v5.20;
use warnings;
use File::Temp ();
use Cwd ();
use FindBin ();
use Test::More;
use Time::Piece ();
use Beam::Make::Cache;

my $cwd = Cwd::getcwd;
my $home = File::Temp->newdir();
chdir $home;

my $cache = Beam::Make::Cache->new( file => '.Beamfile.cache' );

# Each recipe controls how it identifies its data
my $dt = Time::Piece->new;
$cache->set( 'foo', 'abcdef', $dt );
ok -e '.Beamfile.cache', 'cache file is created';

is $cache->last_modified( foo => 'abcdef' ), $dt,
    'cache hit: hash match and last modified is correct';
is $cache->last_modified( foo => 'fedcba' ), 0,
    'cache miss: hash fail, last modified is 0';

# Reload cache from disk
$cache = Beam::Make::Cache->new;
is $cache->last_modified( foo => 'abcdef' ), $dt,
    'cache hit: hash match and last modified is correct';
is $cache->last_modified( foo => 'fedcba' ), 0,
    'cache miss: hash fail, last modified is 0';

chdir $cwd;
done_testing;
