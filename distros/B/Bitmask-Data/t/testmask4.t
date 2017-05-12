# -*- perl -*-

# t/testmask4.t - check testmask 4

use Test::More tests => 5;
use Test::NoWarnings;

use strict;
use warnings;

use lib qw(t/lib);
use_ok( 'Testmask4' );

my $tm = Testmask4->new();

$tm->setall;
is($tm->length,5);
is($tm->integer,63488);
$tm->remove('value1');
is($tm->string,'0111100000000000');



