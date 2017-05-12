use strict;
use warnings;
use Test::More tests => 16;
use Data::FormValidator;
BEGIN {
    use_ok( 'Data::FormValidator::Constraints::MethodsFactory', qw(:num) );
}

###############################################################################
test_FV_clamp: {
    my $results = Data::FormValidator->check(
        { 'too_small'   => 0,
          'too_big'     => 10,
          'just_right'  => 5,
        },
        { 'required'    => [qw( too_small too_big just_right )],
          'constraint_methods' => {
                'too_small'     => FV_clamp(1, 1, 9),
                'too_big'       => FV_clamp(1, 1, 9),
                'just_right'    => FV_clamp(1, 1, 9),
          },
        } );
    ok( !$results->valid('too_small'),      'negative (low) test for FV_clamp' );
    ok( !$results->valid('too_big'),        'negative (high) test for FV_clamp' );
    ok(  $results->valid('just_right'),     'positive test for FV_clamp' );
}

###############################################################################
test_FV_lt: {
    my $results = Data::FormValidator->check(
        { 'too_big'     => 20,
          'border'      => 10,
          'just_right'  => 5,
        },
        { 'required'    => [qw( too_big border just_right )],
          'constraint_methods' => {
                'too_big'       => FV_lt(1, 10),
                'border'        => FV_lt(1, 10),
                'just_right'    => FV_lt(1, 10),
          },
        } );
    ok( !$results->valid('too_big'),        'negative (gt) test for FV_lt' );
    ok( !$results->valid('border'),         'negative (eq) test for FV_lt' );
    ok(  $results->valid('just_right'),     'positive test for FV_lt' );
}

###############################################################################
test_FV_gt: {
    my $results = Data::FormValidator->check(
        { 'too_small'   => 0,
          'border'      => 5,
          'just_right'  => 10,
        },
        { 'required'    => [qw( too_small border just_right )],
          'constraint_methods' => {
                'too_small'     => FV_gt(1, 5),
                'border'        => FV_gt(1, 5),
                'just_right'    => FV_gt(1, 5),
          },
        } );
    ok( !$results->valid('too_small'),      'negative (lt) test for FV_gt' );
    ok( !$results->valid('border'),         'negative (eq) test for FV_gt' );
    ok(  $results->valid('just_right'),     'positive test for FV_gt' );
}

###############################################################################
test_FV_le: {
    my $results = Data::FormValidator->check(
        { 'too_big'     => 20,
          'border'      => 10,
          'just_right'  => 5,
        },
        { 'required'    => [qw( too_big border just_right )],
          'constraint_methods' => {
                'too_big'       => FV_le(1, 10),
                'border'        => FV_le(1, 10),
                'just_right'    => FV_le(1, 10),
          },
        } );
    ok( !$results->valid('too_big'),        'negative test for FV_le' );
    ok(  $results->valid('border'),         'positive (eq) test for FV_le' );
    ok(  $results->valid('just_right'),     'positive (lt) test for FV_le' );
}

###############################################################################
test_FV_ge: {
    my $results = Data::FormValidator->check(
        { 'too_small'   => 0,
          'border'      => 5,
          'just_right'  => 10,
        },
        { 'required'    => [qw( too_small border just_right )],
          'constraint_methods' => {
                'too_small'     => FV_ge(1, 5),
                'border'        => FV_ge(1, 5),
                'just_right'    => FV_ge(1, 5),
          },
        } );
    ok( !$results->valid('too_small'),      'negative test for FV_ge' );
    ok(  $results->valid('border'),         'positive (eq) test for FV_ge' );
    ok(  $results->valid('just_right'),     'positive (gt) test for FV_ge' );
}
