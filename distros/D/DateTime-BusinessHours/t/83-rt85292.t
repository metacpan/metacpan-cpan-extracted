use strict; 
use warnings; 
use Test::More tests => 1; 
use DateTime::BusinessHours; 
use DateTime; 

my $dt1 = DateTime->new( year => 2013, month => 5, day => 14, hour => 3 ); 
my $dt2 = DateTime->new( year => 2013, month => 5, day => 14, hour => 8 ); 
my $t = DateTime::BusinessHours->new( datetime1 => $dt1, datetime2 => $dt2); 
is( $t->gethours(), 0, 'dt1 and dt2 fall outside of working time should return 0' ); 
