#!perl

use Data::Frame::Setup;

use Test2::V0;
use Test2::Tools::Warnings qw/warning/;

use Data::Frame;
use PDL::Core qw(pdl);

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

is( $df_array->column_names, [ qw/z y x/ ] );
is( $df_hash->column_names, [ qw/a b c/ ] );

is( $df_hash->column('c')->length, 4);
{
	my $length;
	like(
		warning { $length = $df_hash->column('c')->number_of_rows },
		qr/deprecated/,
		'Got deprecation warning'
	);
	is($length , 4);
}
is( $df_hash->column('c')->unpdl, $c);

like(
    dies { $df_hash->add_column( c => [ 1, 2, 3, 4 ] ) },
    qr/column.*already exists/,
    'exception for adding existing column'
);

$df_array->column_names(qw/a b c/);
is( $df_array->column_names, [ qw/a b c/ ], 'renaming columns works' );

is( $df_array->row_names->unpdl, [ 0..3 ] );

like(
    dies { $df_array->column_names(qw/a b c d/); },
    qr/incorrect number of column names/,
    'setting more columns than exist'
);

is( $df_hash->nth_column(0)->length, 4);
is( $df_hash->nth_column(-1)->length, 4);

like(
    dies { $df_hash->nth_column(3) },
    qr/index out of bounds/,
    'out of bounds column access'
);

like(
    dies { $df_hash->column('m') },
    qr/column.*does not exist/,
    'non-existent column'
);

done_testing;
