# test the functionality of the Algorithm::AM::DataSet
use strict;
use warnings;
use Test::More 0.88;
plan tests => 26;
use Test::NoWarnings;
use Test::Exception;
use Algorithm::AM::DataSet 'dataset_from_file';
use t::TestAM 'chapter_3_data';
use Path::Tiny;
use FindBin '$Bin';
my $data_dir = path($Bin, 'data');

test_constructor();
test_data();
test_dataset_from_file();
test_private_data();

# test that the constructor lives/dies when given valid/invalid
# parameters, and that state is set correctly
sub test_constructor {
    throws_ok {
        Algorithm::AM::DataSet->new();
    } qr/Failed to provide 'cardinality' parameter/,
    q<dies without 'cardinality' parameter>;

    throws_ok {
        Algorithm::AM::DataSet->new(
            cardinality => 3,
            foo => 'bar',
            baz => 'buff'
        );
    } qr/Unknown parameters in DataSet constructor: baz, foo/,
    'dies with unknown parameters';

    lives_ok {
        Algorithm::AM::DataSet->new(
            cardinality => 3,
        );
    } 'constructor lives with normal input';
    my $dataset = Algorithm::AM::DataSet->new(cardinality => 3);
    is($dataset->cardinality, 3, 'cardinality set by constructor');
    return;
}

# test that add_item correctly adds data to the set and validates input
# TODO: rename this something more descriptive
sub test_data {
    # first check empty DataSet
    my $dataset = Algorithm::AM::DataSet->new(cardinality => 3);
    is($dataset->size, 0, 'new data set has 0 items');
    is($dataset->num_classes, 0, 'new data set has 0 classes');

    $dataset->add_item(
        features => ['a','b','c'],
        class => 'b',
        comment => 'stuff'
    );
    is($dataset->size, 1,
        'add_item adds 1 item to data set');
    is($dataset->num_classes, 1, 'data set has 1 class');

    $dataset->add_item(
        features => ['a','b','d'],
        class => 'c',
        comment => 'stuff'
    );
    is($dataset->num_classes, 2, 'data set has 2 classes');

    is($dataset->get_item(1)->comment, 'stuff', 'get_item');

    throws_ok {
        $dataset->add_item(
            features => ['3','1'],
            class => 'c',
            comment => 'comment'
        );
    } qr/Expected 3 features, but found 2 in 3 1 \(comment\)/,
    'add_item fails with wrong number of features';

    # The error should be thrown from Tiny.pm, the caller of DataSet,
    # not from DataSet (tests that @CARP_NOT is working cardinalityperly).
    throws_ok {
        $dataset->add_item();
    } qr/Must provide 'features' parameter of type array ref.*DataSet.t/,
    'add_item fails with missing features parameter';
    return;
}

# test the dataset_from_file function
sub test_dataset_from_file {
    subtest 'read nocommas data set' => sub {
        plan tests => 5;
        my $dataset = dataset_from_file(
            path => path($data_dir, 'chapter_3_no_commas.txt'),
            format => 'nocommas'
        );
        is($dataset->cardinality, 3, 'cardinality');
        is($dataset->size, 5, 'size');
        my $item = $dataset->get_item(0);
        is($item->class, 'e', 'item class');
        is_deeply($item->features, ['3', '1', '0'],
            'item features');
        is($item->comment, 'myFirstCommentHere');
    };
    subtest 'read commas data set' => sub {
        plan tests => 5;
        my $dataset = dataset_from_file(
            path => path($data_dir, 'chapter_3_commas.txt'),
            format => 'commas'
        );
        is($dataset->cardinality, 3, 'cardinality');
        is($dataset->size, 5, 'size');
        my $item = $dataset->get_item(0);
        is($item->class, 'e', 'item class');
        is_deeply($item->features, ['3', '1', '0'],
            'item features');
        is($item->comment, 'myFirstCommentHere');
    };

    throws_ok {
        my $dataset = dataset_from_file(
            path => path($data_dir, 'chapter_3_commas.txt'),
        );
    } qr/Failed to provide 'format' parameter/,
    'fail with missing format parameter';
    throws_ok {
        my $dataset = dataset_from_file(
            path => path($data_dir, 'chapter_3_commas.txt'),
            format => 'buh'
        );
    } qr/Unknown value buh for format parameter \(should be 'commas' or 'nocommas'\)/,
    'fail with incorrect format parameter';

    throws_ok {
        my $dataset = dataset_from_file(
            format => 'commas'
        );
    } qr/Failed to provide 'path' parameter/,
    'fail with missing path parameter';
    throws_ok {
        my $dataset = dataset_from_file(
            path => path($data_dir, 'nonexistent'),
            format => 'commas'
        );
    } qr/Could not find file .*nonexistent/,
    'fail with non-existent Path';

    throws_ok {
        my $dataset = dataset_from_file(
            path => path($data_dir, 'bad_data_line.txt'),
            format => 'nocommas'
        );
    } qr/Couldn't read data at line 2 in .*bad_data_line/,
    'fail with malformed data file';

    subtest 'data set with default unknown/null labels' => sub {
        plan tests => 3;
        my $dataset = dataset_from_file(
            path => path($data_dir, 'no_labels_default.txt'),
            format => 'commas'
        );
        is($dataset->size, 2, 'size');
        my $item = $dataset->get_item(0);
        is($item->class, undef, 'class is unknown');
        is_deeply($item->features, ['3', '1', ''],
            'third feature is unknown')
    };

    subtest 'data set with custom unknown/null labels' => sub {
        plan tests => 3;
        my $dataset = dataset_from_file(
            path => path($data_dir, 'no_labels_custom.txt'),
            format => 'commas',
            unknown => '?',
            null => 'NUL',
        );
        is($dataset->size, 2, 'size');
        my $item = $dataset->get_item(0);
        is($item->class, undef, 'class is unknown');
        is_deeply($item->features, ['3', '1', ''],
            'third feature is unknown')
    };
    return;
}

# test all data for use by AM.pm (and the hooks) only
# hopefully this can be eliminated in the future, as private
# data should not have to be exposed
sub test_private_data {
    my $dataset = Algorithm::AM::DataSet->new(cardinality => 3);
    is_deeply($dataset->_data_classes, [],
        "empty data set has empty classes");

    my @data = chapter_3_data();
    # get rid of one of the comments to test that it is filled in
    $data[1][2] = '';
    for my $datum(@data){
        $dataset->add_item(
            features =>$datum->[0],
            class => $datum->[1],
            comment => $datum->[2]);
    }

    is_deeply($dataset->_data_classes, [qw(1 2 2 2 2)],
        "list of classes for data set");
    is($dataset->_index_for_class('r'), 2,
        '_index_for_class');
    is($dataset->_class_for_index(2), 'r',
        '_class_for_index');
    return;
}
