# Check AM constructor and acessors (which are related)
use strict;
use warnings;
use Algorithm::AM::Batch;
use Test::More 0.88;
use Test::Exception;
use Test::NoWarnings;
use Test::LongString;
plan tests => 12;
use t::TestAM qw(chapter_3_train chapter_3_test);

test_input_checking();
test_accessors();
test_classify();

sub test_input_checking {
    throws_ok {
        Algorithm::AM::Batch->new();
    } qr/Missing required parameter 'training_set'/,
    'dies when no training set provided';

    throws_ok {
        Algorithm::AM::Batch->new(
            training_set => 'stuff',
        );
    } qr/Parameter training_set should be an Algorithm::AM::DataSet/,
    'dies with bad training set';

    throws_ok {
        Algorithm::AM::Batch->new(
            training_set => Algorithm::AM::DataSet->new(
                cardinality => 3),
            test_set => Algorithm::AM::DataSet->new(
                cardinality => 3),
            foo => 'bar'
        );
    } qr/Invalid attributes for Algorithm::AM::Batch/,
    'dies with bad argument';

    throws_ok {
        my $batch = Algorithm::AM::Batch->new(
            training_set => Algorithm::AM::DataSet->new(
                cardinality => 3)
        );
        $batch->classify_all(Algorithm::AM::DataSet->new(
            cardinality => 4));
    } qr/Training and test sets do not have the same cardinality \(3 and 4\)/,
    'dies with mismatched dataset cardinalities';

    throws_ok {
        my $batch = Algorithm::AM::Batch->new(
            training_set =>
                Algorithm::AM::DataSet->new(cardinality => 3)
        );
        $batch->classify_all();
    } qr/Must provide a DataSet to classify_all/,
    'dies with no input to classify';

    throws_ok {
        my $batch = Algorithm::AM::Batch->new(
            training_set => Algorithm::AM::DataSet->new(
                cardinality => 3),
        );
        $batch->classify_all('foo');
    } qr/Must provide a DataSet to classify_all/,
    'dies with bad test set';
    return;
}

sub test_accessors {
    subtest 'Constructor saves data sets' => sub {
        plan tests => 4;
        my $batch = Algorithm::AM::Batch->new(
            training_set => Algorithm::AM::DataSet->new(
                cardinality => 3),
            test_set => Algorithm::AM::DataSet->new(
                cardinality => 3),
        );
        isa_ok($batch->training_set, 'Algorithm::AM::DataSet',
            'training_set returns correct object type');
        isa_ok($batch->test_set, 'Algorithm::AM::DataSet',
            'test_set returns correct object type');

        is($batch->training_set->cardinality, 3,
            'training set saved');
        is($batch->test_set->cardinality, 3,
            'test set saved');
    };

    subtest 'default configuration' => sub {
        plan tests => 5;
        my $batch = Algorithm::AM::Batch->new(
            training_set => Algorithm::AM::DataSet->new(
                cardinality => 3),
            test_set => Algorithm::AM::DataSet->new(
                cardinality => 3),
        );
        ok($batch->exclude_nulls, 'exclude nulls by default');
        ok($batch->exclude_given, 'exclude given by default');
        ok(!$batch->linear, 'pointer counting is quadratic by default');
        is($batch->probability, 1, 'probability is 1 by default');
        is($batch->repeat, 1, 'repeat is 1 by default');
    };

    subtest 'configuration via constructor' => sub {
        plan tests => 5;
        my $batch = Algorithm::AM::Batch->new(
            training_set => Algorithm::AM::DataSet->new(
                cardinality => 3),
            test_set => Algorithm::AM::DataSet->new(
                cardinality => 3),
            exclude_nulls => 0,
            exclude_given => 0,
            linear => 1,
            probability => .5,
            repeat => 2
        );
        ok(!$batch->exclude_nulls, 'exclude nulls turned off');
        ok(!$batch->exclude_given, 'exclude given turned off');
        ok($batch->linear, 'pointer counting set to linear');
        is($batch->probability, .5, 'probability set to .5');
        is($batch->repeat, 2, 'repeat set to 2');
    };

    subtest 'configuration via accessors' => sub {
        plan tests => 5;
        my $batch = Algorithm::AM::Batch->new(
            training_set => Algorithm::AM::DataSet->new(
                cardinality => 3),
            test_set => Algorithm::AM::DataSet->new(
                cardinality => 3),
        );
        $batch->exclude_nulls(0);
        $batch->exclude_given(0);
        $batch->linear(1);
        $batch->probability(.5);
        $batch->repeat(2);
        ok(!$batch->exclude_nulls, 'exclude nulls turned off');
        ok(!$batch->exclude_given, 'exclude given turned off');
        ok($batch->linear, 'pointer counting set to linear');
        is($batch->probability, .5, 'probability set to .5');
        is($batch->repeat, 2, 'repeat set to 2');
    };
    return;
}

sub test_classify {
    subtest 'run batch classification' => sub {
        plan tests => 8;
        my $train = chapter_3_train();
        my $test = chapter_3_test();
        # just duplicate one item to test classifying multiple items
        $test->add_item($test->get_item(0));
        # add test to train to test exclude_given
        $train->add_item($test->get_item(0));
        my $batch = Algorithm::AM::Batch->new(
            training_set => $train,
            repeat => 2,
            exclude_nulls => 0,
            exclude_given => 0,
            linear => 1,
        );
        my @results = $batch->classify_all($test);
        is(scalar @results, 4, '2 items are analyzed twice') or
            note scalar @results;
        isa_ok($results[0], 'Algorithm::AM::Result');
        isa_ok($results[1], 'Algorithm::AM::Result');
        isa_ok($results[2], 'Algorithm::AM::Result');
        isa_ok($results[3], 'Algorithm::AM::Result');

        # test was in train, so not excluding given would mean that
        # exclude_given was set to false successfully
        # TODO: this seems fragile, as it relies on AM having
        # exclude_given set to true by default.
        ok(!$results[0]->given_excluded,
            'exclude_given passed on to classifier');
        ok(!$results[0]->exclude_nulls,
            'exclude_nulls passed on to classifier');
        is($results[0]->count_method, 'linear',
            'linear passed on to classifier');
    };
    return;
}

