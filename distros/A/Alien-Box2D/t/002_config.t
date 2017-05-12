# t/002_config.t - test config() functionality

use Test::More tests => 3;
use Alien::Box2D;
use Alien::Box2D::ConfigData;

### test some config strings
like( Alien::Box2D->config('version'), qr/([0-9]+\.)*[0-9]+/, "Testing config('version')" );
like( Alien::Box2D->config('prefix'), qr/.+/, "Testing config('prefix')" );

### check if prefix is a real directory
my $p = Alien::Box2D->config('prefix');
is( (-d Alien::Box2D->config('prefix')), 1, "Testing existence of 'prefix' directory" );

diag( "VERSION=" . Alien::Box2D->config('version') );
diag( "PREFIX=" . Alien::Box2D->config('prefix') );
diag( "CFLAGS=" . Alien::Box2D->config('cflags') );
diag( "LIBS=" . Alien::Box2D->config('libs') );

my $m = join ' ', @{Alien::Box2D::ConfigData->config('make_command')};
diag( "make_command=$m" );