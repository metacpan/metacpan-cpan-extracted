# t/001_load.t - test module loading and basic functionality

use Test::More tests => 1;

BEGIN { use_ok( 'Alien::PNG' ); }

diag( "Testing Alien::PNG $Alien::PNG::VERSION, Perl $], $^X" );

diag( "Build type: " . (Alien::PNG::ConfigData->config('build_params')->{buildtype} || 'n.a.') );
diag( "Detected libpng-config script: " . (Alien::PNG::ConfigData->config('build_params')->{script} || 'n.a.') );
diag( "Build option used:\n\t" . (Alien::PNG::ConfigData->config('build_params')->{title} || 'n.a.') );
diag( "URL: " . (Alien::PNG::ConfigData->config('build_params')->{url} || 'n.a.') );
diag( "SHA1: " . (Alien::PNG::ConfigData->config('build_params')->{sha1sum} || 'n.a.') );
