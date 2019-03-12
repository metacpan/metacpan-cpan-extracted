use Test::Most tests => 16;

use strict;
use warnings;

use PDL::Factor;

my $data = [ qw[ a b c a b ] ];
my $f = PDL::Factor->new( $data );

is( $f->nelem, 5 );

is( $f->number_of_levels, 3 );

cmp_set( $f->levels, [qw/a b c/] );

is( "$f", "[ a b c a b ]", 'stringify' );

is( "@{[ $f->uniq ]}", "[ a b c ]" );

# set levels
my $f_set_levels = PDL::Factor->new( $data );
$f_set_levels->levels(qw/z y x/);
is_deeply( $f_set_levels->levels, [qw/z y x/] );

throws_ok
	{ $f_set_levels->levels(qw/z y/); }
	qr/incorrect number of levels/,
	'setting too few levels';

EQUALITY: {
	my $another_f = PDL::Factor->new( $data );
	my $g = PDL::Factor->new( [ qw[a b a a c ] ] );
	my $h = PDL::Factor->new( [ qw[x y z x y ] ] );

	#use DDP; &p( $f!=$g );
	ok( ($f == $another_f)->all, 'factor data is equal' );
	ok( !( ($f == $g)->all ) , 'factor data is not equal' );
	ok( ($f != $g)->any,       'factor data is not equal' );

	throws_ok( sub { $f == $h; },
		qr/level sets of factors are different/,
		'error: different level sets' );
	ok( ($f->{PDL} == $h->{PDL})->all, 'but the internal values are the same');
}

TODO: { # CLONING
	todo_skip "need to implement cloning", 3;

	my $copy_of_f_0 = $f->copy;
	my $copy_of_f_1 = PDL::Factor->new( $f );

	is_deeply($copy_of_f_0->levels, $f->levels);

	ok( $f == $copy_of_f_0 );

	ok( $copy_of_f_0 == $copy_of_f_1 );

	note $copy_of_f_0->PDL::Core::string;

	# table( iris$Species )
	# row.names( table( iris$Species ) )
	# table( iris$Species ) / length( iris$Species )
	# <http://www.cyclismo.org/tutorial/R/types.html>
}

subtest 'max width' => sub {
	plan tests => 4;
	my $width_data = [ qw[ a b cde fghi ]   ];
	my $width_factor = PDL::Factor->new($width_data);
	is( $width_factor->element_stringify_max_width, 4 );
	is( $width_factor->slice('0:2')->element_stringify_max_width, 3 );
	is( $width_factor->slice('0:1')->element_stringify_max_width, 1 );
	is( $width_factor->slice('0')->element_stringify_max_width, 1 );
};


done_testing;
