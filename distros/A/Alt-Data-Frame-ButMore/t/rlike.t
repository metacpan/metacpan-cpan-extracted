use Test::Most tests => 6;

use strict;
use warnings;

use Data::Frame::Rlike;
use PDL;

my $N  = 42;
my $first_x = 0;
my $last_x = $N - 1;
my $df = dataframe( x => sequence($N), y => 3 * sequence($N) );

subtest sanity => sub {
	ok( $df );
	is( $df->number_of_rows, $N );
};

subtest positive_head => sub {
	is( $df->head(2)->number_of_rows, 2 );
	# row.names( head(iris, 2) ): 1 - 2
	is( $df->head(2)->nth_column(0)->at(0), $first_x );
	is( $df->head(2)->nth_column(0)->at(-1), $first_x + 1 );
};

subtest negative_head => sub {
	is( $df->head(-2)->number_of_rows, $N - 2 );
	# row.names( head(iris, -1) ): 1 - 149
	is( $df->head(-1)->nth_column(0)->at(0), $first_x );
	is( $df->head(-1)->nth_column(0)->at(-1), $last_x - 1 );
};

subtest positive_tail => sub {
	is( $df->tail(2)->number_of_rows, 2 );
	# row.names( tail(iris, 2) ) : 149 - 150
	is( $df->tail(2)->nth_column(0)->at(0), $last_x - 1 );
	is( $df->tail(2)->nth_column(0)->at(-1), $last_x );
};

subtest negative_tail => sub {
	is( $df->tail(-2)->number_of_rows, $N - 2 );
	# row.names( tail(iris, -1) ) : 2 - 150
	is( $df->tail(-1)->nth_column(0)->at(0), $first_x + 1 );
	is( $df->tail(-1)->nth_column(0)->at(-1), $last_x );
};

subtest extreme_values => sub {
	# 0 gives no rows
	is( $df->head(0)->number_of_rows, 0 );
	is( $df->tail(0)->number_of_rows, 0 );

	# $N gets all $N
	is( $df->head($N)->number_of_rows, $N );
	is( $df->tail($N)->number_of_rows, $N );

	# $N + 1 still gets all $N
	is( $df->head($N+1)->number_of_rows, $N );
	is( $df->tail($N+1)->number_of_rows, $N );

	# -$N gives 0
	is( $df->head(-$N)->number_of_rows, 0 );
	is( $df->tail(-$N)->number_of_rows, 0 );
};

done_testing;
