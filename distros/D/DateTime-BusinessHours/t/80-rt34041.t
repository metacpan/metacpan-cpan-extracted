use strict;
use warnings;

use Test::More tests => 4;

use_ok( 'DateTime::BusinessHours' );
use DateTime;

my $d1 = DateTime->new( year => 2007, month => 10, day => 15, hour => 12 );
my $d2 = DateTime->new( year => 2007, month => 10, day => 15, hour => 15 );

my $t = DateTime::BusinessHours->new(
    datetime1 => $d1,
    datetime2 => $d2,
);

isa_ok( $t, 'DateTime::BusinessHours' );

is( $t->getdays,  3 / 8, 'getdays' );
is( $t->gethours, 3, 'gethours' );
