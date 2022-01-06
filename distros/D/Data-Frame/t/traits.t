#!perl

use Data::Frame::Setup;

use Test2::V0;

use Data::Frame;
use PDL::Basic qw(sequence);

my $N  = 5;
my $colspec = [ x => sequence($N), y => 3 * sequence($N) ];
my $df = Data::Frame->with_traits( 'Rlike' )->new( columns => $colspec );

can_ok( $df, qw(head tail) );

is( $df->head(2)->number_of_rows, 2 );

done_testing;
