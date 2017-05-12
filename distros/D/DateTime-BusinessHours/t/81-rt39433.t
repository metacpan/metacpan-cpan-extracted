use strict;
use warnings;

use Test::More tests => 4;

use_ok( 'DateTime::BusinessHours' );
use DateTime;

my $d1 = DateTime->new( year => 2008, month => 7, day => 1 );
my $d2 = DateTime->new( year => 2008, month => 8, day => 1 );

my $t = DateTime::BusinessHours->new(
    datetime1 => $d1,
    datetime2 => $d2,
);

isa_ok( $t, 'DateTime::BusinessHours' );

is( $t->getdays,  23,     'getdays' );
is( $t->gethours, 23 * 8, 'gethours' );
