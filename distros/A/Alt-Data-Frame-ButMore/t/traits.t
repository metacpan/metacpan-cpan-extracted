use Test::Most tests => 2;

use strict;
use warnings;

use Data::Frame;
use PDL;

my $N  = 5;
my $colspec = [ x => sequence($N), y => 3 * sequence($N) ];
my $df = Data::Frame->with_traits( 'Rlike' )->new( columns => $colspec );

can_ok( $df, qw(head tail) );

is( $df->head(2)->number_of_rows, 2 );

done_testing;
