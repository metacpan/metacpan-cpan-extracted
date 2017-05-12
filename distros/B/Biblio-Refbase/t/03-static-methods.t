#!perl -T

use strict;
use warnings;

use Test::More tests => 6;

use Biblio::Refbase;

my $refbase = 'Biblio::Refbase';



#
#  formats
#

can_ok $refbase, 'formats';

my $scalar = $refbase->formats;
ok     !defined $scalar, 'formats returned undef in scalar context';
my @array = $refbase->formats;
ok     @array > 0, 'formats returned a non-empty list';



#
#  styles
#

can_ok $refbase, 'styles';

$scalar = $refbase->styles;
ok     !defined $scalar, 'styles returned undef in scalar context';
@array = $refbase->styles;
ok     @array > 0, 'styles returned a non-empty list';
