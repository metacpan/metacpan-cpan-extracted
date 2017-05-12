# -*- perl -*-

# t/testmask3.t - check testmask 3

use Test::More tests => 7;
use Test::NoWarnings;

use strict;
use warnings;

use lib qw(t/lib);
use_ok( 'Testmask3' );

my $tm = Testmask3->new();

$tm->setall;
is($tm->length,3);
is($tm->integer,7);
$tm->remove('w');
is($tm->length,2);
is($tm->string,'101');
$tm->neg();
is($tm->string,'010');