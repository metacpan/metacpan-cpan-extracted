use strict;
use warnings;

use Test::More tests => 4;

use_ok( 'DateTime::BusinessHours' );
use DateTime;

my $d1 = DateTime->new( year => 2012, month => 6, day => 27 );
my $d2 = $d1->clone->add( days => 1, hours => 13 );

my $t = DateTime::BusinessHours->new( datetime1 => $d1, datetime2 => $d2 );
isa_ok( $t, 'DateTime::BusinessHours' );

is( $t->getdays,  1.5, 'getdays' );
is( $t->gethours, 12, 'gethours' );
