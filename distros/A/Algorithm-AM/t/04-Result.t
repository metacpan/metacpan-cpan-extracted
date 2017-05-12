use strict;
use warnings;
use Test::More 0.88;
plan tests => 7;
use Test::LongString;
use Test::Deep;
use Path::Tiny;
use FindBin '$Bin';
# TODO: Remove the use of Algorithm::AM so that the
# tests aren't co-dependent
use Algorithm::AM;
use t::TestAM qw(chapter_3_train chapter_3_test);

test_config_info();

my $am = Algorithm::AM->new(
    training_set => chapter_3_train(),
);
my $result = $am->classify(chapter_3_test->get_item(0));
test_statistical_summary($result);
test_aset_summary($result);
test_gang_summary($result);
test_undefined_result($am);
test_scores($result);

# test that the configuration information is correctly printed by
# the config_info method after setting internal state through
# the constructor.
sub test_config_info {
    my $train = chapter_3_train();
    my $item = Algorithm::AM::DataSet::Item->new(
        features => [qw(a b c)],
        comment => 'comment',
        class => 'e',
    );
    subtest 'configuration info string' => sub {
        plan tests => 2;
        my $result = Algorithm::AM::Result->new(
            test_item => $item,
            given_excluded => 1,
            cardinality => 3,
            exclude_nulls => 1,
            count_method => 'linear',
            test_in_train => 1,
            training_set => $train
        );
        my $info = ${$result->config_info};
        my $expected = <<'END_INFO';
+---------------------------+----------------+
| Option                    | Setting        |
+---------------------------+----------------+
| Given context             | a b c, comment |
| Nulls                     | exclude        |
| Gang                      | linear         |
| Test item in training set | yes            |
| Test item excluded        | yes            |
| Size of training set      | 5              |
| Number of active features | 3              |
+---------------------------+----------------+
END_INFO
        is_string_nows($info, $expected,
            'given/nulls excluded, linear, test in train')
            or note $info;
        $result = Algorithm::AM::Result->new(
            given_excluded => 0,
            cardinality => 3,
            test_item => $item,
            exclude_nulls => 0,
            count_method => 'squared',
            test_in_train => 0,
            training_set => $train,
        );

        $info = ${$result->config_info};
        $expected = <<'END_INFO';
+---------------------------+----------------+
| Option                    | Setting        |
+---------------------------+----------------+
| Given context             | a b c, comment |
| Nulls                     | include        |
| Gang                      | squared        |
| Test item in training set | no             |
| Test item excluded        | no             |
| Size of training set      | 5              |
| Number of active features | 3              |
+---------------------------+----------------+
END_INFO
        is_string_nows($info, $expected,
            'given/nulls included, linear, test not in train')
            or note $info;
    };
    return;
}

# test the statistical_summary method; mock the result method
# and see if the printout uses the returned info correctly.
sub test_statistical_summary{
    my ($result) = @_;
    subtest 'statistical summary' => sub {
        plan tests => 4;
        my $stats = ${$result->statistical_summary};
        my $expected = <<'END_STATS';
Statistical Summary
+-------+-------+------------+
| Class | Score | Percentage |
+-------+-------+------------+
| e     |  4    |  30.769    |
| r     |  9    |  69.231    |
+-------+-------+------------+
| Total | 13    |            |
+-------+-------+------------+
Expected class: r
Correct class predicted.
END_STATS

        is_string_nows($stats, $expected, 'statistical summary')
            or note $stats;

        # check that statistical_summary correctly prints out the
        # incorrect and tie results.
        {
            no warnings 'redefine';
            local *Algorithm::AM::Result::result = sub {
                return 'incorrect';
            };
            $stats = ${$result->statistical_summary};
            $expected = <<'END_STATS';
Statistical Summary
+-------+-------+------------+
| Class | Score | Percentage |
+-------+-------+------------+
| e     |  4    |  30.769    |
| r     |  9    |  69.231    |
+-------+-------+------------+
| Total | 13    |            |
+-------+-------+------------+
Expected class: r
Incorrect class predicted.
END_STATS
            is_string_nows($stats, $expected,
                'statistical summary (incorrect class)') or
                note $stats;

        }
        {
            no warnings 'redefine';
            local *Algorithm::AM::Result::result = sub {
                return 'tie';
            };
            $stats = ${$result->statistical_summary};
            $expected = <<'END_STATS';
Statistical Summary
+-------+-------+------------+
| Class | Score | Percentage |
+-------+-------+------------+
| e     |  4    |  30.769    |
| r     |  9    |  69.231    |
+-------+-------+------------+
| Total | 13    |            |
+-------+-------+------------+
Expected class: r
Prediction is a tie.
END_STATS
            is_string_nows($stats, $expected,
                'statistical summary (tie)') or
                note $stats;
        }

        # remove the class label and test printing for unlabeled item
        my $item = new_item(
            features => [qw(3 1 2)],
            comment => 'test item comment'
        );
        $result = $am->classify($item);
        $stats = ${$result->statistical_summary};
        $expected = <<'END_STATS';
Statistical Summary
+-------+-------+------------+
| Class | Score | Percentage |
+-------+-------+------------+
| e     |  4    |  30.769    |
| r     |  9    |  69.231    |
+-------+-------+------------+
| Total | 13    |            |
+-------+-------+------------+
Expected class unknown
END_STATS
        is_string_nows($stats, $expected,
            'statistical summary (unlabeled)') or
            note $stats;
    };
    return;
}

# test the analogical set summary
sub test_aset_summary {
    my ($result) = @_;
    my $set = ${$result->analogical_set_summary};
    my $expected = <<'END_SET';
Analogical Set
Total Frequency = 13
+-------+---------------------+-------+------------+
| Class | Item                | Score | Percentage |
+-------+---------------------+-------+------------+
| e     | myFirstCommentHere  | 4     |  30.769    |
| r     | myThirdCommentHere  | 2     |  15.385    |
| r     | myFourthCommentHere | 3     |  23.077    |
| r     | myFifthCommentHere  | 4     |  30.769    |
+-------+---------------------+-------+------------+
END_SET
    is_string_nows($set, $expected, 'analogical set printout') or
        note $set;
    return;
}

# Test the gang summary, with and without individual items included
sub test_gang_summary {
    my ($result) = @_;
    subtest 'gang printing' => sub {
        plan tests => 3;
        my $gang = ${$result->gang_summary(0)};
        my $expected = <<'END_GANG';
+------------+-------+-----------+-------+-------+
| Percentage | Score | Num Items | Class |       |
| Context    |       |           |       | 3 1 2 |
+------------+-------+-----------+-------+-------+
**************************************************
|  61.538    | 8     |           |       | 3 1 * |
+------------+-------+-----------+-------+-------+
|  30.769    | 4     | 1         | e     |       |
|  30.769    | 4     | 1         | r     |       |
**************************************************
|  23.077    | 3     |           |       | * 1 2 |
+------------+-------+-----------+-------+-------+
|  23.077    | 3     | 1         | r     |       |
**************************************************
|  15.385    | 2     |           |       | * * 2 |
+------------+-------+-----------+-------+-------+
|  15.385    | 2     | 1         | r     |       |
+------------+-------+-----------+-------+-------+
END_GANG
        is_string_nows($gang, $expected,
            'gang summary without items') or note $gang;
        $gang = ${$result->gang_summary(1)};

        $expected = <<'END_GANG';
+------------+-------+-----------+-------+-------+---------------------+
| Percentage | Score | Num Items | Class |       | Item Comment        |
| Context    |       |           |       | 3 1 2 |                     |
+------------+-------+-----------+-------+-------+---------------------+
************************************************************************
|  61.538    | 8     |           |       | 3 1 * |                     |
+------------+-------+-----------+-------+-------+---------------------+
|  30.769    | 4     | 1         | e     |       |                     |
|            |       |           |       | 3 1 0 | myFirstCommentHere  |
|  30.769    | 4     | 1         | r     |       |                     |
|            |       |           |       | 3 1 1 | myFifthCommentHere  |
************************************************************************
|  23.077    | 3     |           |       | * 1 2 |                     |
+------------+-------+-----------+-------+-------+---------------------+
|  23.077    | 3     | 1         | r     |       |                     |
|            |       |           |       | 2 1 2 | myFourthCommentHere |
************************************************************************
|  15.385    | 2     |           |       | * * 2 |                     |
+------------+-------+-----------+-------+-------+---------------------+
|  15.385    | 2     | 1         | r     |       |                     |
|            |       |           |       | 0 3 2 | myThirdCommentHere  |
+------------+-------+-----------+-------+-------+---------------------+
END_GANG
        is_string_nows($gang, $expected,
            'gang summary with items') or note $gang;

        # now test the printing of 'false' features ('0', etc.)
        my $mini_finn_data = dataset_from_file(
            path => path($Bin, 'data', 'finnverb_mini.txt'),
            format => 'nocommas',
        );
        my $am = Algorithm::AM->new(
            training_set => $mini_finn_data,
        );
        $result = $am->classify($mini_finn_data->get_item(0));
        $gang = ${$result->gang_summary()};
        ok($gang =~ /\QA A 0 * 0 * 0 * * A\E/,
            'features with "false" value are printed') or note $gang;
    };
    return;
}

# make sure that no correct/incorrect result is provided for an
# unlabeled item
sub test_undefined_result {
    my ($am) = @_;
    my $item = new_item(
        features => [qw(3 1 2)],
        comment => 'test item comment'
    );
    my $result = $am->classify($item);
    is($result->result, undef, 'result is undef for unlabeled item');
}

sub test_scores {
    my ($result) = @_;
    is_deeply($result->scores, {'e' => 4, 'r' => 9},
        'scores') or note explain $result->scores;
    cmp_deeply($result->scores_normalized,
        {'e' => num(.3076923, .00001), 'r' => num(.6923077, .00001)},
        'normalized scores') or
        note explain $result->scores_normalized;
}
