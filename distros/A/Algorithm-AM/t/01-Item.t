# test the functionality of the Algorithm::AM::DataSet
use strict;
use warnings;
use Test::More 0.88;
plan tests => 13;
use Test::NoWarnings;
use Test::Exception;
use Algorithm::AM::DataSet::Item 'new_item';

test_constructor();
test_accessors();

# test that the constructor lives/dies when given valid/invalid parameters
sub test_constructor {
    # The error should be thrown from Tiny.pm, the caller of DataSet,
    # not from DataSet (tests that @CARP_NOT is working properly).
    throws_ok {
        Algorithm::AM::DataSet::Item->new();
    } qr/Must provide 'features' parameter of type array ref.*Item.t/,
    'constructor dies with missing features parameter';

    throws_ok {
        Algorithm::AM::DataSet::Item->new(features => 'hello');
    } qr/Must provide 'features' parameter of type array ref.*Item.t/,
    'constructor dies with incorrect features parameter';

    throws_ok {
        Algorithm::AM::DataSet::Item->new(
            features => ['a'],
            foo => 'baz',
            bar => 'qux'
        );
    } qr/Unknown parameters: bar,foo.*Item.t/,
    'constructor dies with unknown parameters';

    my $item = Algorithm::AM::DataSet::Item->new(features => ['a','b']);
    isa_ok($item, 'Algorithm::AM::DataSet::Item');

    $item = new_item(features => ['a','b']);
    isa_ok($item, 'Algorithm::AM::DataSet::Item');

    return;
}

# test that accessors work and have correct defaults
sub test_accessors {
    my $item_1 = Algorithm::AM::DataSet::Item->new(
        features => ['a', 'b'], class => 'zed', comment => 'xyz');
    is_deeply($item_1->features, ['a', 'b'], 'features value');
    is($item_1->class, 'zed', 'class value');
    is($item_1->comment, 'xyz', 'comment value');
    is($item_1->cardinality, 2, 'cardinality');

    my $item_2 = Algorithm::AM::DataSet::Item->new(
        features => ['a', 'b', '']);
    is($item_2->class, undef, 'class default value');
    is($item_2->comment, 'a,b,', 'comment default value');

    ok($item_1->id ne $item_2->id, q[unique items have unique id's])
        or note q[item id's are both ] . $item_1->id;
    note $item_1->id;
}
