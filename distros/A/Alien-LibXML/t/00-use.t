use strict;
use warnings;

use Test::More tests => 1;
use Alien::LibXML;

use Text::ParseWords qw/shellwords/;

my @libs = shellwords( Alien::LibXML->libs );

my ($libname) = grep { s/^-l// } @libs;
is( $libname, 'xml2', 'idenitified needed library' );

