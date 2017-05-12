# t/001_load.t - test module loading and basic functionality

use Test::More tests => 1;

BEGIN { use_ok( 'Alien::CMake' ); }

diag( "Testing Alien::CMake $Alien::CMake::VERSION, Perl $], $^X" );

diag( "Build type: " . (Alien::CMake::ConfigData->config('build_params')->{buildtype} || 'n.a.') );
diag( "Build option used:\n\t" . (Alien::CMake::ConfigData->config('build_params')->{title} || 'n.a.') );
diag( "URL: " . (Alien::CMake::ConfigData->config('build_params')->{url} || 'n.a.') );
diag( "SHA1: " . (Alien::CMake::ConfigData->config('build_params')->{sha1sum} || 'n.a.') );
