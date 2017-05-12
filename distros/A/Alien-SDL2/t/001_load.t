# t/001_load.t - test module loading and basic functionality

use Test::More tests => 1;

BEGIN { use_ok( 'Alien::SDL2' ); }

diag( "Testing Alien::SDL2 $Alien::SDL2::VERSION, Perl $], $^X" );

diag( "Build type: " . (Alien::SDL2::ConfigData->config('build_params')->{buildtype} || 'n.a.') );
diag( "Detected sdl2-config script: " . (Alien::SDL2::ConfigData->config('build_params')->{script} || 'n.a.') );
diag( "Build option used:\n\t" . (Alien::SDL2::ConfigData->config('build_params')->{title} || 'n.a.') );
my $urls = Alien::SDL2::ConfigData->config('build_params')->{url} || [ 'n.a.' ];
diag( "URL:\n\t" . join("\n\t", @$urls));
diag( "SHA1: " . (Alien::SDL2::ConfigData->config('build_params')->{sha1sum} || 'n.a.') );
