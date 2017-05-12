use strict;
use warnings;

use Test::More tests => 11;
use DateTime::BusinessHours;
use DateTime;

# start and end on weekend days
# see RT
my $d1 = DateTime->new( year => 2013, month => 11, day => 9); #sat
my $d2 = $d1->clone->add( days => 1 ); #sun
my $t = DateTime::BusinessHours->new( datetime1 => $d1, datetime2 => $d2 );
isa_ok( $t, 'DateTime::BusinessHours' );
is( $t->getdays,  0, 'getdays returns 0 starting and ending on weekend' );
is( $t->gethours, 0, 'gethours returns 0 starting and ending on weekend' );

# start on weekend, end on weekday
# See RT 82432
$d1 = DateTime->new( year => 2013, month => 11, day => 10, hour => 12); # Sun
$d2 = DateTime->new( year => 2013, month => 11, day => 11, hour => 12); # Mon
$t = DateTime::BusinessHours->new( datetime1 => $d1, datetime2 => $d2 );
is( $t->getdays,  3 / 8, 'getdays starting on weekend, ending on weekday' );
is( $t->gethours, 3, 'gethours starting on weekend, ending on weekday' );

# cross weekends completely
$d1 = DateTime->new( year => 2013, month => 11, day => 8, hour => 12 ); #friday 12pm
$d2 = DateTime->new( year => 2013, month => 11, day => 11, hour => 10 ); # Monday, 10am
$t = DateTime::BusinessHours->new( datetime1 => $d1, datetime2 => $d2 );
is( $t->getdays, 6 / 8, 'getdays spanning weekend');
is( $t->gethours, 6, 'gethours spanning weekend');

# larger intervals cross weekends
$d1 = DateTime->new( year => 2013, month => 11, day => 8, hour => 12 ); #Friday 12pm 
$d2 = DateTime->new( year => 2013, month => 11, day => 12, hour => 12 ); # Tuesday 12pm
$t = DateTime::BusinessHours->new( datetime1 => $d1, datetime2 => $d2 ); 
is( $t->getdays, 2, 'getdays spanning weekend, larger interval');
is( $t->gethours, 16, 'gethours spanning weekend, larger interval');

# span many weekends
$d1 = DateTime->new( year => 2013, month => 11, day => 8);
$d2 = DateTime->new( year => 2013, month => 11, day => 30);
$t = DateTime::BusinessHours->new( datetime1 => $d1, datetime2 => $d2 ); 
is( $t->getdays, 16, 'getdays spanning multiple weekend');
is( $t->gethours, 16 * 8, 'gethours spanning multiple weekend');

