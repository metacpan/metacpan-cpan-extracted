use strict;
use warnings;

use Test::More tests => 1;
use Alien::AntTweakBar;

use Text::ParseWords qw/shellwords/;

my @libs = shellwords( Alien::AntTweakBar->config('libs') );

my ($libname) = grep { s/^-l// } @libs;
is( $libname, 'AntTweakBar', 'idenitified needed library' );

diag( "CFLAGS=" . Alien::AntTweakBar->config('cflags') );
diag( "LIBS=" . Alien::AntTweakBar->config('libs') );
