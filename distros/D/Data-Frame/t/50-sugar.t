#!perl

use Data::Frame::Setup;

use PDL::Core qw(pdl);

use Test2::V0;
use Test2::Tools::DataFrame;
use Test2::Tools::PDL;

use Data::Frame;
use Data::Frame::Examples qw(mtcars);

my $mtcars = mtcars();

subtest keys => sub {
    is( [ keys %$mtcars ], $mtcars->names, 'keys %$mtcars' );
};

subtest string_key => sub {
    pdl_is( $mtcars->{mpg}, $mtcars->at('mpg'), '$mtcars->{mpg}' );

    my $df = $mtcars->copy;
    $df->{kpg} = $df->{mpg} * 1.609;
    dataframe_is(
        $df,
        $mtcars->transform(
            {
                kpg => sub { my ( $col, $df ) = @_; $df->at('mpg') * 1.609; }
            }
        ),
        '$mtcars->{mpg} STORE'
    );
};

subtest arrayref_key => sub {
    dataframe_is(
        $mtcars->{ ['mpg'] },
        $mtcars->slice( [qw(mpg)] ),
        '$mtcars->{["mpg"]}'
    );
    dataframe_is(
        $mtcars->{ [qw(mpg cyl)] },
        $mtcars->slice( [qw(mpg cyl)] ),
        '$mtcars->{["mpg", "cyl"]}'
    );

};

done_testing;
