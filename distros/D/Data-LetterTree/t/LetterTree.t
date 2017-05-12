use Test::More tests => 11;

BEGIN {
	use_ok('Data::LetterTree')
};

my $tree = Data::LetterTree->new();
isa_ok($tree, 'NodePtr', 'constructor works');

# scalar tests
$tree->add_data('scalar1', 'value1');
$tree->add_data('scalar2', 'value2');
$tree->add_data('scalar2', 'value3');

ok($tree->has_word('scalar1'), 'single value scalar node existence');
ok($tree->has_word('scalar2'), 'multiple value scalar existence');
ok(!$tree->has_word('scalar3'), 'unknown node inexistence');

is(
    $tree->get_data('scalar1'),
    'value1',
    'single scalar value retrieval'
);
is_deeply(
    [ $tree->get_data('scalar2') ],
    [ 'value2', 'value3' ],
    'multiple scalar values retrieval'
);

# arrayref tests
my $arrayref = ['value1', 'value2']; 
$tree->add_data('array', $arrayref);
ok($tree->has_word('array'), 'array node existence');
ok(
    $tree->get_data('array') == $arrayref,
    'array retrieval'
);

# hashref tests
my $hashref = { key1 => 'value1', key2 => 'value2'}; 
$tree->add_data('hash', $hashref);
ok($tree->has_word('hash'), 'hash node existence');
ok(
    $tree->get_data('hash') == $hashref,
    'hash retrieval'
);
