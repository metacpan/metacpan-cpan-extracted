# t/002_config.t - test config() functionality

use Test::More tests => 3;
use Alien::CMake;

### test some config strings
like( Alien::CMake->config('version'), qr/([0-9]+\.)*[0-9]+/, "Testing config('version')" );
like( Alien::CMake->config('prefix'), qr/.+/, "Testing config('prefix')" );

### check if prefix is a real directory
my $p = Alien::CMake->config('prefix');
is( (-d Alien::CMake->config('prefix')), 1, "Testing existence of 'prefix' directory" );

diag( "BIN=" . Alien::CMake->config('bin') );
diag( "SHARE=" . Alien::CMake->config('share') );
