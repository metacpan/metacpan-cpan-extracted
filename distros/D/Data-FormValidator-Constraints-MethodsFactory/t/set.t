use strict;
use warnings;
use Test::More tests => 9;
use Data::FormValidator;
BEGIN {
    use_ok( 'Data::FormValidator::Constraints::MethodsFactory', qw(:set) );
}

###############################################################################
test_FV_set: {
    my $results = Data::FormValidator->check(
        { 'in_set'      => 'in',
          'missing'     => 'missing',
        },
        { 'required'    => [qw( in_set missing )],
          'constraint_methods' => {
                'in_set'    => FV_set( 1, qw(in here somewhere) ),
                'missing'   => FV_set( 1, qw(but not over here) ),
          },
        } );
    ok(  $results->valid('in_set'),     'positive test for FV_set' );
    ok( !$results->valid('missing'),    'negative test for FV_set' );
}

###############################################################################
test_FV_set_num: {
    my $results = Data::FormValidator->check(
        { 'in_set'      => 5,
          'missing'     => 10,
        },
        { 'required'    => [qw( in_set missing )],
          'constraint_methods' => {
                'in_set'    => FV_set_num(1, (1 .. 9) ),
                'missing'   => FV_set_num(1, (1 .. 9) ),
          },
        } );
    ok(  $results->valid('in_set'),     'positive test for FV_set_num' );
    ok( !$results->valid('missing'),    'negative test for FV_set_num' );
}

###############################################################################
test_FV_set_word: {
    my $results = Data::FormValidator->check(
        { 'in_set'      => 'in',
          'missing'     => 'missing',
        },
        { 'required'    => [qw( in_set missing )],
          'constraint_methods' => {
                'in_set'    => FV_set_word(1, 'in here somewhere' ),
                'missing'   => FV_set_word(1, 'but not over here' ),
          },
        } );
    ok(  $results->valid('in_set'),     'positive test for FV_set_word' );
    ok( !$results->valid('missing'),    'negative test for FV_set_word' );
}

###############################################################################
test_FV_set_cmp: {
    my $results = Data::FormValidator->check(
        { 'in_set'      => 'in',
          'missing'     => 'missing',
        },
        { 'required'    => [qw( in_set missing )],
          'constraint_methods' => {
                'in_set'    => FV_set_cmp(1, sub { $_[0] eq $_[1] }, qw(in here somewhere) ),
                'missing'   => FV_set_cmp(1, sub { $_[0] eq $_[1] }, qw(but not over here) ),
          },
        } );
    ok(  $results->valid('in_set'),     'positive test for FV_set_cmp' );
    ok( !$results->valid('missing'),    'negative test for FV_set_cmp' );
}
