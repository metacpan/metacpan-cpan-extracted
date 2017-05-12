use Bubblegum;
use Test::More;
use Scalar::Util qw(refaddr);

ok ! main->isa('Moo::Object'), 'class not an object';

can_ok 'Bubblegum::Object::Array', 'all';
subtest 'test the all method' => sub {
    my $array = [2..5];
    ok $array->all('$a > 1'); # 1; true
    ok !$array->all('$a > 3'); # 0; false
};

can_ok 'Bubblegum::Object::Array', 'any';
subtest 'test the any method' => sub {
    my $array = [2..5];
    ok !$array->any('$a > 5'); # 0; false
    ok $array->any('$a > 3'); # 1; true
};

can_ok 'Bubblegum::Object::Array', 'clear';
subtest 'test the clear method' => sub {
    my $addr = refaddr(my $array = ['a'..'g']);
    $array->clear; # []
    ok $addr == refaddr($array) && !@{$array};
};

can_ok 'Bubblegum::Object::Array', 'count';
subtest 'test the count method' => sub {
    my $array = [1..5];
    is $array->count, 5; # 5
};

can_ok 'Bubblegum::Object::Array', 'defined';
subtest 'test the defined method' => sub {
    my $array = [1,2,undef,4,5];
    ok !$array->defined(2); # 0; false
    ok $array->defined(1); # 1; true
};

can_ok 'Bubblegum::Object::Array', 'delete';
subtest 'test the delete method' => sub {
    my $array = [1..5];
    is $array->delete(2), 3; # 3
    is $array->get(2), undef;
    is $#{$array}, 4;
};

can_ok 'Bubblegum::Object::Array', 'each';
subtest 'test the each method' => sub {
    my $array   = ['a'..'g'];
    my $indices = [];
    my $values  = [];
    $array->each(sub{
        push @{$indices}, shift; # 0
        push @{$values}, shift; # a
    });
    is_deeply $indices, [qw(0 1 2 3 4 5 6)];
    is_deeply $values, [qw(a b c d e f g)];
};

can_ok 'Bubblegum::Object::Array', 'each_key';
subtest 'test the each_key method' => sub {
    my $array = ['a'..'g'];
    my $keys  = [];
    $array->each_key(sub{
        my $index = shift; # 0
        push @{$keys}, $index;
    });
    is_deeply $keys, [qw(0 1 2 3 4 5 6)];
};

can_ok 'Bubblegum::Object::Array', 'each_n_values';
subtest 'test the each_n_values method' => sub {
    my $array  = ['a'..'g'];
    my $values = [];
    $array->each_n_values(4, sub{
        my $value_1 = shift; # a
        my $value_2 = shift; # b
        my $value_3 = shift; # c
        my $value_4 = shift; # d
        my $value_5 = shift; # undef
        my $value_6 = shift; # undef
        push @{$values}, $value_1;
        push @{$values}, $value_2;
        push @{$values}, $value_3;
        push @{$values}, $value_4;
        push @{$values}, $value_5;
        push @{$values}, $value_6;
    });
    is_deeply $values,
        [qw(a b c d), undef, undef, qw(e f g), undef, undef, undef];
};

can_ok 'Bubblegum::Object::Array', 'each_value';
subtest 'test the each_value method' => sub {
    my $array  = ['a'..'g'];
    my $values = [];
    $array->each_value(sub{
        push @{$values}, shift; # a
    });
    is_deeply $values, [qw(a b c d e f g)];
};

can_ok 'Bubblegum::Object::Array', 'empty';
subtest 'test the empty method' => sub {
    my $addr = refaddr(my $array = ['a'..'g']);
    $array->empty; # []
    ok $addr == refaddr($array) && !@{$array};
};

can_ok 'Bubblegum::Object::Array', 'exists';
subtest 'test the exists method' => sub {
    my $array = [1,2,3,4,5];
    ok !($array->exists(5)); # 0; false
    ok $array->exists(0); # 1; true
};

can_ok 'Bubblegum::Object::Array', 'first';
subtest 'test the first method' => sub {
    my $array = [1..5];
    is $array->first, 1; # 1
};

can_ok 'Bubblegum::Object::Array', 'get';
subtest 'test the get method' => sub {
    my $array = [1..5];
    is $array->get(0), 1; # 1;
};

can_ok 'Bubblegum::Object::Array', 'grep';
subtest 'test the grep method' => sub {
    my $array = [1..5];
    is_deeply [3,4,5], $array->grep(sub{
        shift >= 3
    });
};

can_ok 'Bubblegum::Object::Array', 'hashify';
subtest 'test the hashify method' => sub {
    my $array = [1..5];
    is_deeply $array->hashify, {1=>1,2=>1,3=>1,4=>1,5=>1};
};

can_ok 'Bubblegum::Object::Array', 'head';
subtest 'test the head method' => sub {
    my $array = [1..5];
    is $array->head, 1; # 1
};

can_ok 'Bubblegum::Object::Array', 'iterator';
subtest 'test the iterator method' => sub {
    my $array  = [1..5];
    my $values = [];
    my $i      = 0;
    my $iterator = $array->iterator;
    while (my $value = $iterator->next) {
        $i++;
        push @{$values}, $value;
    }
    is $i, 5;
    is_deeply $values, [qw(1 2 3 4 5)];
};

can_ok 'Bubblegum::Object::Array', 'join';
subtest 'test the join method' => sub {
    my $array = [1..5];
    is $array->join, 12345; # 12345
    is $array->join(', '), '1, 2, 3, 4, 5'; # 1, 2, 3, 4, 5
};

can_ok 'Bubblegum::Object::Array', 'keyed';
subtest 'test the keyed method' => sub {
    my $array = [1..5];
    is_deeply {a=>1,b=>2,c=>3,d=>4},
        $array->keyed('a'..'d'); # {a=>1,b=>2,c=>3,d=>4}
};

can_ok 'Bubblegum::Object::Array', 'keys';
subtest 'test the keys method' => sub {
    my $array = ['a'..'d'];
    is_deeply [0,1,2,3], $array->keys; # [0,1,2,3]
};

can_ok 'Bubblegum::Object::Array', 'last';
subtest 'test the last method' => sub {
    my $array = [1..5];
    is $array->last, 5; # 5
};

can_ok 'Bubblegum::Object::Array', 'length';
subtest 'test the length method' => sub {
    my $array = [1..5];
    is $array->length, 5; # 5
    push @{$array}, undef;
    is $array->length, 6; # 6
};

can_ok 'Bubblegum::Object::Array', 'list';
subtest 'test the list method' => sub {
    my $array = [1..5];
    my @flat  = $array->list; # (1,2,3,4,5)
    is $#flat, 4;
    is_deeply \@flat, [qw(1 2 3 4 5)];
};

can_ok 'Bubblegum::Object::Array', 'map';
subtest 'test the map method' => sub {
    my $array  = [1..5];
    my $values = [];
    $array->map(sub{
        push @{$values}, shift() + 1;
    });
    is_deeply $values, [qw(2 3 4 5 6)];
};

can_ok 'Bubblegum::Object::Array', 'max';
subtest 'test the max method' => sub {
    my $array = [8,9,1,2,3,undef,4,5,{},[]];
    is $array->max, 9; # 9
};

can_ok 'Bubblegum::Object::Array', 'min';
subtest 'test the min method' => sub {
    my $array = [8,9,1,2,3,undef,4,5,{},[]];
    is $array->min, 1; # 1
    delete $array->[2];
    delete $array->[3];
    delete $array->[4];
    is $array->min, 4; # 4
};

can_ok 'Bubblegum::Object::Array', 'none';
subtest 'test the none method' => sub {
    my $array = [2..5];
    ok $array->none('$a <= 1'); # 1; true
    ok !$array->none('$a <= 2'); # 0; false
};

can_ok 'Bubblegum::Object::Array', 'nsort';
subtest 'test the nsort method' => sub {
    my $array = [5,4,3,2,1];
    is_deeply $array->nsort, [qw(1 2 3 4 5)]; # [1,2,3,4,5]
};

can_ok 'Bubblegum::Object::Array', 'one';
subtest 'test the one method' => sub {
    my $array = [2..5,7,7];
    ok $array->one('$a == 5'); # 1; true
    ok !$array->one('$a == 6'); # 0; false
    ok !$array->one('$a == 7'); # 0; false
};

can_ok 'Bubblegum::Object::Array', 'pairs';
subtest 'test the pairs method' => sub {
    my $array = [1..5];
    is_deeply $array->pairs,
        [[0,1],[1,2],[2,3],[3,4],[4,5]]; # [[0,1],[1,2],[2,3],[3,4],[4,5]]
};

can_ok 'Bubblegum::Object::Array', 'pairs_array';
subtest 'test the pairs_array method' => sub {
    my $array = [1..5];
    is_deeply $array->pairs,
        [[0,1],[1,2],[2,3],[3,4],[4,5]]; # [[0,1],[1,2],[2,3],[3,4],[4,5]]
};

can_ok 'Bubblegum::Object::Array', 'pairs_hash';
subtest 'test the pairs_hash method' => sub {
    my $array = [1..5];
    is_deeply $array->pairs_hash,
        {0=>1,1=>2,2=>3,3=>4,4=>5}; # {0=>1,1=>2,2=>3,3=>4,4=>5}
};

can_ok 'Bubblegum::Object::Array', 'part';
subtest 'test the part method' => sub {
    my $array = [1..10];
    is_deeply $array->part(sub { shift > 5 }),
        [[6, 7, 8, 9, 10], [1, 2, 3, 4, 5]]; # [[6, 7, 8, 9, 10], [1, 2, 3, 4, 5]]
};

can_ok 'Bubblegum::Object::Array', 'pop';
subtest 'test the pop method' => sub {
    my $array = [1..5];
    is $array->pop, 5; # 5
    is $array->pop, 4; # 5
    is $array->pop, 3; # 5
    is $array->pop, 2; # 5
    is $array->pop, 1; # 5
    is $array->pop, undef; # undef
};

can_ok 'Bubblegum::Object::Array', 'print';
subtest 'test the print method' => sub {
    my $array = [];
    is 1, $array->print; # ''
    is 1, $array->print(''); # ''
};

can_ok 'Bubblegum::Object::Array', 'push';
subtest 'test the push method' => sub {
    my $array = [1..5];
    is_deeply $array->push(6,7,8), [1,2,3,4,5,6,7,8]; # [1,2,3,4,5,6,7,8]
    is_deeply $array, [1,2,3,4,5,6,7,8]; # [1,2,3,4,5,6,7,8]
};

can_ok 'Bubblegum::Object::Array', 'random';
subtest 'test the random method' => sub {
    my $array = [1..5];
    for (my $i=0; $i < 10; $i++) {
        my $x = $array->random;
        ok $x == 1
        || $x == 2
        || $x == 3
        || $x == 4
        || $x == 5
    }
};

can_ok 'Bubblegum::Object::Array', 'reverse';
subtest 'test the reverse method' => sub {
    my $array = [1..5];
    is_deeply $array->reverse, [qw(5 4 3 2 1)]; # [5,4,3,2,1]
};

can_ok 'Bubblegum::Object::Array', 'rotate';
subtest 'test the rotate method' => sub {
    my $array = [1..5];
    is_deeply $array->rotate, [qw(2 3 4 5 1)]; # [2,3,4,5,1]
    is_deeply $array->rotate, [qw(3 4 5 1 2)]; # [3,4,5,1,2]
    is_deeply $array->rotate, [qw(4 5 1 2 3)]; # [4,5,1,2,3]
    is_deeply $array, [qw(4 5 1 2 3)]; # [4,5,1,2,3]
};

can_ok 'Bubblegum::Object::Array', 'rnsort';
subtest 'test the rnsort method' => sub {
    my $array = [5,4,3,2,1];
    is_deeply $array->rnsort, [qw(5 4 3 2 1)]; # [5,4,3,2,1]
};

can_ok 'Bubblegum::Object::Array', 'rsort';
subtest 'test the rsort method' => sub {
    my $array = ['a'..'d'];
    is_deeply $array->rsort, [qw(d c b a)]; # ['d','c','b','a']
};

can_ok 'Bubblegum::Object::Array', 'say';
subtest 'test the say method' => sub {
    my $array = [];
    is 1, $array->say; # ''
    is 1, $array->say(''); # ''
};

can_ok 'Bubblegum::Object::Array', 'set';
subtest 'test the set method' => sub {
    my $array = [1..5];
    is $array->set(4,6), 6;
    is_deeply $array, [qw(1 2 3 4 6)]; # [1,2,3,4,6]
};

can_ok 'Bubblegum::Object::Array', 'shift';
subtest 'test the shift method' => sub {
    my $array = [1..5];
    is $array->shift, 1; # 1
    is $array->shift, 2; # 2
    is $array->shift, 3; # 3
    is $array->shift, 4; # 4
    is $array->shift, 5; # 5
    is_deeply $array, [];
};

can_ok 'Bubblegum::Object::Array', 'size';
subtest 'test the size method' => sub {
    my $array = [1..5];
    is $array->size, 5; # 5
};

can_ok 'Bubblegum::Object::Array', 'slice';
subtest 'test the slice method' => sub {
    my $array = [1..5];
    is_deeply $array->slice(2,4), [3,5]; # [3,5]
    is_deeply $array, [1,2,3,4,5];
};

can_ok 'Bubblegum::Object::Array', 'sort';
subtest 'test the sort method' => sub {
    my $array = ['d','c','b','a'];
    is_deeply $array->sort, [qw(a b c d)]; # ['a','b','c','d']
};

can_ok 'Bubblegum::Object::Array', 'sum';
subtest 'test the sum method' => sub {
    my $array = [1..5];
    is $array->sum, 15; # 15
};

can_ok 'Bubblegum::Object::Array', 'tail';
subtest 'test the tail method' => sub {
    my $array = [1..5];
    is_deeply $array->tail, [qw(2 3 4 5)]; # [2,3,4,5]
};

can_ok 'Bubblegum::Object::Array', 'unique';
subtest 'test the unique method' => sub {
    my $array = [1,1,1,1,2,3,1];
    is_deeply $array->unique, [qw(1 2 3)]; # [1,2,3]
};

can_ok 'Bubblegum::Object::Array', 'unshift';
subtest 'test the unshift method' => sub {
    my $array = [1..5];
    is_deeply $array->unshift(-2,-1,0),
        [-2,-1,0,1,2,3,4,5]; # [-2,-1,0,1,2,3,4,5]
    is_deeply $array, [-2,-1,0,1,2,3,4,5]; # [-2,-1,0,1,2,3,4,5]
};

can_ok 'Bubblegum::Object::Array', 'values';
subtest 'test the values method' => sub {
    my $array = [1..5];
    is_deeply $array->values, [1,2,3,4,5]; # [1,2,3,4,5]
};

done_testing;
