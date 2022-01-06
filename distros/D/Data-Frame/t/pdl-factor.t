#!perl

use Data::Frame::Setup;

use Test2::V0;

use PDL::Factor ();

my $data = [ qw[ a b c a b ] ];
my $f = PDL::Factor->new( $data );

is( $f->nelem, 5 );

is( $f->number_of_levels, 3 );

is( $f->levels, [qw/a b c/] );

is( "$f", "[ a b c a b ]", 'stringify' );

is( "@{[ $f->uniq ]}", "[ a b c ]" );

# set levels
my $f_set_levels = PDL::Factor->new( $data );
$f_set_levels->levels(qw/z y x/);
is( $f_set_levels->levels, [qw/z y x/] );

like(
    dies { $f_set_levels->levels(qw/z y/); },
    qr/incorrect number of levels/,
    'setting too few levels'
);

EQUALITY: {
	my $another_f = PDL::Factor->new( $data );
	my $g = PDL::Factor->new( [ qw[a b a a c ] ] );
	my $h = PDL::Factor->new( [ qw[x y z x y ] ] );

	ok( ($f == $another_f)->all, 'factor data is equal' );
	ok( !( ($f == $g)->all ) , 'factor data is not equal' );
	ok( ($f != $g)->any,       'factor data is not equal' );

    like(
        dies { $f == $h; },
        qr/level sets of factors are different/,
        'error: different level sets'
    );
	ok( ($f->{PDL} == $h->{PDL})->all, 'but the internal values are the same');
}

subtest 'max width' => sub {
	my $width_data = [ qw[ a b cde fghi ]   ];
	my $width_factor = PDL::Factor->new($width_data);
	is( $width_factor->element_stringify_max_width, 4 );
	is( $width_factor->slice('0:2')->element_stringify_max_width, 3 );
	is( $width_factor->slice('0:1')->element_stringify_max_width, 1 );
	is( $width_factor->slice('0')->element_stringify_max_width, 1 );
};


done_testing;
