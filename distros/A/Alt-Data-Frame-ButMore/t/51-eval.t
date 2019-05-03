#!perl

use Data::Frame::Setup;

use PDL::Core qw(pdl);

use Test2::V0;
use Test2::Tools::PDL;

use Data::Frame::Examples qw(mtcars);

my $mtcars = mtcars();

subtest eval_tidy => sub {
    pdl_is( $mtcars->eval_tidy('wt'),      $mtcars->at('wt'),     'eval_tidy' );
    pdl_is( $mtcars->eval_tidy('$wt * 2'), $mtcars->at('wt') * 2, 'eval_tidy' );

    eval { $mtcars->eval_tidy('somethingnotexist'); };
    like(
        $@,
        qr/^Error in eval_tidy\(.* : Bareword/,
        'eval_tidy() error message'
    );
};

done_testing;
