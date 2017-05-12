use Test::Most tests => 16;

use strict;
use warnings;

use Data::Frame;
use PDL;

my $a = pdl(1, 2, 3, 4);
my $b = $a >= 2;
my $c = [ qw/foo bar baz quux/ ];

my $df_array = Data::Frame->new( columns => [
	z => $a,
	y => $b,
	x => $c,
] );

my $df_hash = Data::Frame->new( columns => {
	b => $b,
	c => $c,
	a => $a,
} );

is($df_array->number_of_columns, 3);
is($df_hash->number_of_columns, 3);

is($df_array->number_of_rows, 4);
is($df_hash->number_of_rows, 4);

is_deeply( $df_array->column_names, [ qw/z y x/ ] );
is_deeply( $df_hash->column_names, [ qw/a b c/ ] );

is( $df_hash->column('c')->number_of_rows, 4);
is_deeply( $df_hash->column('c')->unpdl, $c);

throws_ok { $df_hash->add_column( c => [1, 2, 3, 4] ) }
	qr/column.*already exists/,
	'exception for adding existing column';

$df_array->column_names(qw/a b c/);
is_deeply( $df_array->column_names, [ qw/a b c/ ], 'renaming columns works' );

is_deeply( $df_array->row_names->unpdl, [ 0..3 ] );

throws_ok
	{ $df_array->column_names(qw/a b c d/); }
	qr/incorrect number of column names/,
	'setting more columns than exist';

is( $df_hash->nth_column(0)->number_of_rows, 4);
is( $df_hash->nth_column(-1)->number_of_rows, 4);

throws_ok
	{ $df_hash->nth_column(3) }
	qr/index out of bounds/,
	'out of bounds column access';

throws_ok
	{ $df_hash->column('m') }
	qr/column.*does not exist/,
	'non-existent column';

done_testing;
