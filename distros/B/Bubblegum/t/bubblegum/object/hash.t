use Bubblegum;
use Test::More;
use Scalar::Util qw(refaddr);

ok ! main->isa('Moo::Object'), 'class not an object';

can_ok 'Bubblegum::Object::Hash', 'aslice';
subtest 'test the aslice method' => sub {
    my $hash = {1..8};
    is_deeply $hash->aslice(1,3), [2,4]; # [2,4]
    is_deeply $hash->aslice(5,7), [6,8]; # [6,8]
};

can_ok 'Bubblegum::Object::Hash', 'array_slice';
subtest 'test the array_slice method' => sub {
    my $hash = {1..8};
    is_deeply $hash->array_slice(1,3), [2,4]; # [2,4]
    is_deeply $hash->array_slice(5,7), [6,8]; # [6,8]
};

can_ok 'Bubblegum::Object::Hash', 'clear';
subtest 'test the clear method' => sub {
    my $addr = refaddr(my $hash = {1..8});
    $hash->clear; # {}
    ok $addr == refaddr($hash);
    is_deeply $hash, {};
};

can_ok 'Bubblegum::Object::Hash', 'defined';
subtest 'test the defined method' => sub {
    my $hash = {1..8,9,undef};
    ok $hash->defined(1); # 1; true
    ok !($hash->defined(0)); # 0; false
    ok !($hash->defined(9)); # 0; false
};

can_ok 'Bubblegum::Object::Hash', 'delete';
subtest 'test the delete method' => sub {
    my $hash = {1..8};
    is $hash->delete(1), 2; # 2
    is_deeply $hash, {3..8};
};

can_ok 'Bubblegum::Object::Hash', 'each';
subtest 'test the each method' => sub {
    my $hash = {1..8};
    my $data = {};
    $hash->each(sub{
        my $key   = shift; # 1
        my $value = shift; # 2
        $data->{$key} = $value;
    });
    is_deeply $hash, $data;
};

can_ok 'Bubblegum::Object::Hash', 'each_key';
subtest 'test the each_key method' => sub {
    my $hash = {1..8};
    my $keys = [];
    $hash->each_key(sub{
        my $key = shift; # 1
        push @{$keys}, $key;
    });
    is_deeply [sort @{$keys}], [sort keys %{$hash}];
};

can_ok 'Bubblegum::Object::Hash', 'each_n_values';
subtest 'test the each_n_values method' => sub {
    my $hash = {1..8};
    my $values = [];
    $hash->each_n_values(3, sub {
        push @{$values}, 0 + @_;
    });
    is_deeply $values, [3,1];
};

can_ok 'Bubblegum::Object::Hash', 'each_value';
subtest 'test the each_value method' => sub {
    my $hash = {1..8};
    my $values = [];
    $hash->each_value(sub {
        my $value = shift; # 2
        push @{$values}, $value;
    });
    is_deeply [sort @{$values}], [sort values %{$hash}];
};

can_ok 'Bubblegum::Object::Hash', 'empty';
subtest 'test the empty method' => sub {
    my $addr = refaddr(my $hash = {1..8});
    $hash->empty; # {}
    ok $addr == refaddr($hash);
    is_deeply $hash, {};
};

can_ok 'Bubblegum::Object::Hash', 'exists';
subtest 'test the exists method' => sub {
    my $hash = {1..8,9,undef};
    ok $hash->exists(1); # 1; true
    ok !($hash->exists(0)); # 0; false
};

can_ok 'Bubblegum::Object::Hash', 'filter_exclude';
subtest 'test the filter_exclude method' => sub {
    my $hash = {1..8};
    my $data = $hash->filter_exclude(1,3); # {5=>6,7=>8}
    is_deeply $data, {5=>6,7=>8};
};

can_ok 'Bubblegum::Object::Hash', 'filter_include';
subtest 'test the filter_include method' => sub {
    my $hash = {1..8};
    my $data = $hash->filter_include(1,3); # {1=>2,3=>4}
    is_deeply $data, {1=>2,3=>4}
};

can_ok 'Bubblegum::Object::Hash', 'get';
subtest 'test the get method' => sub {
    my $hash = {1..8};
    is $hash->get(5), 6; # 6
};

can_ok 'Bubblegum::Object::Hash', 'hash_slice';
subtest 'test the hash_slice method' => sub {
    my $hash = {1..8};
    my $data = $hash->hash_slice(1,3); # {1=>2,3=>4}
    is_deeply $data, {1=>2,3=>4};
};

can_ok 'Bubblegum::Object::Hash', 'hslice';
subtest 'test the hslice method' => sub {
    my $hash = {1..8};
    my $data = $hash->hslice(1,3); # {1=>2,3=>4}
    is_deeply $data, {1=>2,3=>4};
};

can_ok 'Bubblegum::Object::Hash', 'invert';
subtest 'test the invert method' => sub {
    my $addr = refaddr(my $hash = {1..8,9,undef,10,''});
    my $data = $hash->invert; # {''=>10,2=>1,4=>3,6=>5,8=>7}
    ok $addr == refaddr($hash);
    is_deeply $data, {''=>10,2=>1,4=>3,6=>5,8=>7};
};

can_ok 'Bubblegum::Object::Hash', 'iterator';
subtest 'test the iterator method' => sub {
    my $hash = {1..8};
    my $values = [];
    my $iterator = $hash->iterator;
    while (my $value = $iterator->next) {
        push @{$values}, $value; # 2
    }
    is_deeply [sort @{$values}], [sort values %{$hash}];
};

can_ok 'Bubblegum::Object::Hash', 'keys';
subtest 'test the keys method' => sub {
    my $hash = {1..8};
    my $data = $hash->keys; # [1,3,5,7]
    is_deeply [sort @{$data}], [sort keys %{$hash}];
};

can_ok 'Bubblegum::Object::Hash', 'lookup';
subtest 'test the lookup method' => sub {
    my $hash = {1..3,{4,{5,6,7,{8,9,10,11}}}};
    is_deeply $hash->lookup('3.4.7'), {8=>9,10=>11}; # {8=>9,10=>11}
    is_deeply $hash->lookup('3.4'), {5=>6,7=>{8=>9,10=>11}};
    is $hash->lookup(2), undef; # undef
    is $hash->lookup(1), 2; # 2
};

can_ok 'Bubblegum::Object::Hash', 'pairs';
subtest 'test the pairs method' => sub {
    my $hash = {1..8};
    my $data = $hash->pairs; # [[1,2],[3,4],[5,6],[7,8]]
    is 4, @{$data};
    for (@{$data}) {
        is_deeply $_, [$_->[0], $_->[0] + 1]
    }
};

can_ok 'Bubblegum::Object::Hash', 'pairs_array';
subtest 'test the pairs_array method' => sub {
    my $hash = {1..8};
    my $data = $hash->pairs_array; # [[1,2],[3,4],[5,6],[7,8]]
    is 4, @{$data};
    for (@{$data}) {
        is_deeply $_, [$_->[0], $_->[0] + 1]
    }
};

can_ok 'Bubblegum::Object::Hash', 'list';
subtest 'test the list method' => sub {
    my $hash = {1..8};
    my %data = $hash->list; # (1,2,3,4,5,6,7,8)
    is_deeply \%data, $hash;
};

can_ok 'Bubblegum::Object::Hash', 'merge';
subtest 'test the merge method' => sub {
    my $hash = {1..8};
    my $data = $hash->merge({7,7,9,9}); # {1=>2,3=>4,5=>6,7=>7,9=>9}
    is_deeply $data, {1=>2,3=>4,5=>6,7=>7,9=>9};
};

can_ok 'Bubblegum::Object::Hash', 'print';
subtest 'test the print method' => sub {
    my $hash = {};
    is 1, $hash->print; # ''
    is 1, $hash->print(''); # ''
};

can_ok 'Bubblegum::Object::Hash', 'reset';
subtest 'test the reset method' => sub {
    my $hash = {1..8};
    my $data = $hash->reset; # {1=>undef,3=>undef,5=>undef,7=>undef}
    is_deeply $data, {1=>undef,3=>undef,5=>undef,7=>undef};
};

can_ok 'Bubblegum::Object::Hash', 'reverse';
subtest 'test the reverse method' => sub {
    my $hash = {1..8,9,undef};
    my $data = $hash->reverse; # {8=>7,6=>5,4=>3,2=>1}
    is_deeply $data, {8=>7,6=>5,4=>3,2=>1};
};

can_ok 'Bubblegum::Object::Hash', 'say';
subtest 'test the say method' => sub {
    my $hash = {};
    is 1, $hash->say; # ''
    is 1, $hash->say(''); # ''
};

can_ok 'Bubblegum::Object::Hash', 'set';
subtest 'test the set method' => sub {
    my $hash = {1..8};
    is $hash->set(1,10), 10; # 10
    is $hash->set(1,12), 12; # 12
    $hash->set(1,0); # 0
    is_deeply $hash, {1,0,3,4,5,6,7,8};
};

can_ok 'Bubblegum::Object::Hash', 'values';
subtest 'test the values method' => sub {
    my $hash = {1..8};
    my $data = $hash->values; # [2,4,6,8]
    is_deeply [sort @{$data}], [sort values %{$hash}];
};

done_testing;
