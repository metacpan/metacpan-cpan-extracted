##-*- Mode: CPerl -*-
use strict;
use warnings;

use Test::More tests => 1;
use Alien::Unicruft;

use Text::ParseWords qw/shellwords/;
my @libs = shellwords( Alien::Unicruft->libs );

my ($libname) = grep { s/^-l// } @libs;
is( $libname, 'unicruft', 'idenitified needed library' );

