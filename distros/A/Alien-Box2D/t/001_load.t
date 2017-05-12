# t/001_load.t - test module loading and basic functionality

use Test::More tests => 1;

BEGIN { use_ok( 'Alien::Box2D' ); }

diag( "Testing Alien::Box2D $Alien::Box2D::VERSION, Perl $], $^X" );

diag( "URL: " . (Alien::Box2D::ConfigData->config('build_params')->{url} || 'n.a.') );
diag( "SHA1: " . (Alien::Box2D::ConfigData->config('build_params')->{sha1sum} || 'n.a.') );
