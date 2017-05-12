##-*- Mode: CPerl -*-
use strict;
use warnings;

use Test::More tests => 1;
use Alien::Moot;

use Text::ParseWords qw/shellwords/;
my @libs = shellwords( Alien::Moot->libs );

my ($libname) = grep { s/^-l// } @libs;
is( $libname, 'moot', 'idenitified needed library' );
