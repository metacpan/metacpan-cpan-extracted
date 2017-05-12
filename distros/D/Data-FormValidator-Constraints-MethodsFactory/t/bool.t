use strict;
use warnings;
use Test::More tests => 8;
use Data::FormValidator;
BEGIN {
    use_ok( 'Data::FormValidator::Constraints::MethodsFactory', qw(:set :bool :num) );
}

###############################################################################
test_FV_not: {
    my $results = Data::FormValidator->check(
        { 'yes'     => 'yes',
          'no'      => 'no',
        },
        { 'required'    => [qw( yes no )],
          'constraint_methods' => {
              'yes' => FV_not( FV_set(1,'no') ),
              'no'  => FV_not( FV_set(1,'no') ),
          },
        } );
    ok(  $results->valid('yes'),            'positive test for FV_not' );
    ok( !$results->valid('no'),             'negative test for FV_not' );
}

###############################################################################
test_FV_or: {
    my $results = Data::FormValidator->check(
        { 'first'   => 'first',
          'second'  => 'second',
          'nomatch' => 'nomatch',
        },
        { 'required'    => [qw( first second nomatch )],
          'constraint_methods' => {
                'first'     => FV_or(
                    FV_set(1, qw(first match)),
                    FV_set(1, qw(second match)),
                    ),
                'second'    => FV_or(
                    FV_set(1, qw(first match)),
                    FV_set(1, qw(second match)),
                    ),
                'nomatch'   => FV_or(
                    FV_set(1, qw(first match)),
                    FV_set(1, qw(second match)),
                    ),
          },
        } );
    ok(  $results->valid('first'),      'positive (first) test for FV_or' );
    ok(  $results->valid('second'),     'positive (second) test for FV_or' );
    ok( !$results->valid('nomatch'),    'negative test for FV_or' );
}

###############################################################################
test_FV_and: {
    my $results = Data::FormValidator->check(
        { 'good'    => 5,
          'bad'     => 20,
        },
        { 'required'    => [qw( good bad )],
          'constraint_methods' => {
                'good'  => FV_and(
                    FV_gt(1, 0),
                    FV_lt(1, 10),
                    ),
                'bad'   => FV_and(
                    FV_gt(1, 0),
                    FV_lt(1, 10),
                    ),
          },
        } );
    ok(  $results->valid('good'),       'positive test for FV_and' );
    ok( !$results->valid('bad'),        'negative test for FV_and' );
}
