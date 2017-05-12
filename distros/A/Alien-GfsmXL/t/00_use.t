##-*- Mode: CPerl -*-
use strict;
use warnings;

use Test::More tests => 1;
use Alien::GfsmXL;

use Text::ParseWords qw/shellwords/;
my @libs = shellwords( Alien::GfsmXL->libs );

my ($libname) = grep { s/^-l// } @libs;
is( $libname, 'gfsmxl', 'idenitified needed library' );

