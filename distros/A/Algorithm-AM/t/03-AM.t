# Test correct classification.
# Mostly uses the example from chapter 3 of the green book

use strict;
use warnings;
use Algorithm::AM;
use Test::More 0.88;
plan tests => 14;
use Test::NoWarnings;
use Test::Exception;
use Test::Deep;
use t::TestAM qw(chapter_3_train chapter_3_test);

use FindBin qw($Bin);
use Path::Tiny;

test_input_checking();
test_accessors();


my $train = chapter_3_train();
my $test = chapter_3_test()->get_item(0);
my $result = Algorithm::AM->new(training_set => $train)->classify($test);

test_quadratic_classification($result);
test_analogical_set($result);
test_gang_effects($result);

test_linear_classification();
test_nulls();
test_given();

# test that methods die with bad input
sub test_input_checking {
    throws_ok {
        Algorithm::AM->new();
    } qr/Missing required parameter 'training_set'/,
    'dies when no training set provided';

    throws_ok {
        Algorithm::AM->new(
            training_set => 'stuff',
        );
    } qr/Parameter training_set should be an Algorithm::AM::DataSet/,
    'dies with bad training set';

    throws_ok {
        Algorithm::AM->new(
            training_set => Algorithm::AM::DataSet->new(
                cardinality => 3),
            foo => 'bar'
        );
    } qr/Invalid attributes for Algorithm::AM: foo/,
    'dies with bad argument';

    throws_ok {
        my $am = Algorithm::AM->new(
            training_set => Algorithm::AM::DataSet->new(cardinality => 3),
        );
        $am->classify(
            Algorithm::AM::DataSet::Item->new(
                features => ['a']
            )
        );
    } qr/Training set and test item do not have the same cardinality \(3 and 1\)/,
    'dies with mismatched train/test cardinalities';

    return;
}

# test that constructor sets state properly
sub test_accessors {
    subtest 'AM constructor saves data set' => sub {
        plan tests => 2;
        my $am = Algorithm::AM->new(
            training_set => Algorithm::AM::DataSet->new(cardinality => 3),
        );
        isa_ok($am->training_set, 'Algorithm::AM::DataSet',
            'training_set returns correct object type');

        is($am->training_set->cardinality, 3,
            'training set saved');
    };
}

# test classification results using quadratic counting
sub test_quadratic_classification {
    my ($result) = @_;
    subtest 'quadratic calculation' => sub {
        plan tests => 3;
        is($result->total_points, 13, 'total pointers')
            or note $result->total_points;
        is($result->count_method, 'squared',
            'counting configured to quadratic');
        is_deeply($result->scores, {'e' => 4, 'r' => 9},
            'class scores') or
            note explain $result->scores;
    };
    return;
}

# test classification results using linear counting
sub test_linear_classification {
    subtest 'linear calculation' => sub {
        plan tests => 3;
        my $am = Algorithm::AM->new(
            training_set => $train,
            linear => 1
        );
        my ($result) = $am->classify($test);
        is($result->total_points, 7, 'total pointers')
            or note $result->total_points;;
        is($result->count_method, 'linear',
            'counting configured to quadratic');
        is_deeply($result->scores, {'e' => 2, 'r' => 5}, 'class scores')
            or note explain $result->scores;
    };
    return;
}

# test with null features, using both exclude_nulls
# and include_nulls
# TODO: test for the correct number of active features
sub test_nulls {
    my $test = Algorithm::AM::DataSet::Item->new(
        features => ['', '1', '2'],
        class => 'r',
    );
    my $am = Algorithm::AM->new(
        training_set => $train,
    );

    subtest 'exclude nulls' => sub {
        plan tests => 3;
        $am->exclude_nulls(1);
        my ($result) = $am->classify($test);
        is($result->total_points, 10, 'total pointers')
            or note $result->total_points;
        ok($result->exclude_nulls, 'exclude nulls is true');
        is_deeply($result->scores, {'e' => 3, 'r' => 7},
            'class scores')
            or note explain $result->scores;
    };

    subtest 'include nulls' => sub {
        plan tests => 3;
        $am->exclude_nulls(0);
        my ($result) = $am->classify($test);
        is($result->total_points, 5, 'total pointers')
            or note $result->total_points;
        ok(!$result->exclude_nulls, 'exclude nulls is false');
        is_deeply($result->scores, {'r' => 5}, 'class scores')
            or note explain $result->scores;
    };

    return;
}

# test case where test iitem is in training data
sub test_given {
    my $train = chapter_3_train();
    $train->add_item(
        features => [qw(3 1 2)],
        class => 'r',
        comment => 'same as the test item'
    );
    my $am = Algorithm::AM->new(
        training_set => $train,
    );

    subtest 'exclude given' => sub {
        plan tests => 3;
        my ($result) = $am->classify($test);
        is($result->total_points, 13, 'total pointers')
            or note $result->total_points;
        ok($result->given_excluded, 'given item was excluded');
        is_deeply($result->scores, {'e' => 4, 'r' => 9}, 'class scores')
            or note explain $result->scores;
    };

    subtest 'include given' => sub {
        plan tests => 3;
        $am->exclude_given(0);
        my ($result) = $am->classify($test);
        is($result->total_points, 15, 'total pointers')
            or note $result->total_points;
        ok(!$result->given_excluded, 'given was not excluded');
        is_deeply($result->scores, {'r' => 15}, 'class scores')
            or note explain $result->scores;
    };
    return;
}

sub test_analogical_set {
    my ($result) = @_;
    my $set = $result->analogical_set();

    cmp_deeply([values %$set],
      # use bag() and values so we can ignore the keys, which
      # are id strings that might change
      bag({
        'item' => all(
          isa('Algorithm::AM::DataSet::Item'),
          methods(
            features => [qw(3 1 0)],
            class => 'e',
            comment => 'myFirstCommentHere'
          )
        ),
        'score' => '4'
      },
      {
        'item' => all(
          isa('Algorithm::AM::DataSet::Item'),
          methods(
            features => [qw(0 3 2)],
            class => 'r',
            comment => 'myThirdCommentHere'
          )
        ),
        'score' => '2'
      },
      {
        'item' => all(
          isa('Algorithm::AM::DataSet::Item'),
          methods(
            features => [qw(2 1 2)],
            class => 'r',
            comment => 'myFourthCommentHere'
          )
        ),
        'score' => '3'
      },
      {
        'item' => all(
          isa('Algorithm::AM::DataSet::Item'),
          methods(
            features => [qw(3 1 1)],
            class => 'r',
            comment => 'myFifthCommentHere'
          )
        ),
        'score' => '4'
      }),
      'analogical set') or note explain $set;
    return;
}

sub test_gang_effects {
    my ($result) = @_;
    cmp_deeply($result->gang_effects,
        [
          {
            'data' => {
              'r' => [
                all(
                  isa('Algorithm::AM::DataSet::Item'),
                  methods(
                    features => [qw(3 1 1)],
                    class => 'r',
                    comment => 'myFifthCommentHere'
                  )
                )
              ],
              'e' => [
                all(
                  isa('Algorithm::AM::DataSet::Item'),
                  methods(
                    features => [qw(3 1 0)],
                    class => 'e',
                    comment => 'myFirstCommentHere'
                  )
                )
              ]
            },
            'effect' => num(0.6154, 0.001),
            'homogenous' => 0,
            'class' => {
              'e' => {
                'effect' => num(0.3077, 0.001),
                'score' => 4
              },
              'r' => {
                'effect' => num(0.3077, 0.001),
                'score' => 4
              }
            },
            'score' => 8,
            'size' => 2,
            'features' => ['3','1', '']
          },
          {
            'data' => {
              'r' => [
                all(
                  isa('Algorithm::AM::DataSet::Item'),
                  methods(
                    features => [qw(2 1 2)],
                    class => 'r',
                    comment => 'myFourthCommentHere'
                  )
                )
              ]
            },
            'effect' => num(0.2307, 0.001),
            'homogenous' => 'r',
            'class' => {
              'r' => {
                'effect' => num(0.2307, 0.001),
                'score' => '3'
              }
            },
            'score' => 3,
            'size' => 1,
            'features' => ['','1','2']
          },
          {
            'data' => {
              'r' => [
                all(
                  isa('Algorithm::AM::DataSet::Item'),
                  methods(
                    features => [qw(0 3 2)],
                    class => 'r',
                    comment => 'myThirdCommentHere'
                  )
                )
              ]
            },
            'effect' => num(.1538, 0.001),
            'homogenous' => 'r',
            'class' => {
              'r' => {
                'effect' => num(0.1538, 0.001),
                'score' => '2'
              }
            },
            'score' => 2,
            'size' => 1,
            'features' => ['','','2']
          },
        ],
    'correct reported gang effects') or
        note explain $result->gang_effects;

    return;
}
