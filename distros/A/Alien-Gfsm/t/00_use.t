##-*- Mode: CPerl -*-
use strict;
use warnings;

use Test::More tests => 1;
use Alien::Gfsm;

use Text::ParseWords qw/shellwords/;
my @libs = shellwords( Alien::Gfsm->libs );

my ($libname) = grep { s/^-l// } @libs;
is( $libname, 'gfsm', 'idenitified needed library' );

