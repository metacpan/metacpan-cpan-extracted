use Bubblegum;
use Test::More;

ok ! main->isa('Moo::Object'), 'class not an object';

can_ok 'Bubblegum::Object::Integer', 'downto';
subtest 'test the downto method' => sub {
    my $int = 10;
    is_deeply $int->downto(0), # [10,9,8,7,6,5,4,3,2,1,0]
        [10,9,8,7,6,5,4,3,2,1,0];
};

can_ok 'Bubblegum::Object::Integer', 'eq';
subtest 'test the eq method' => sub {
    my $int = 98765;
    is 1, $int->eq(98765); # true
    is 1, $int->eq('98765'); # true
    is 0, $int->eq(987650); # false
};

can_ok 'Bubblegum::Object::Integer', 'eqtv';
subtest 'test the eqtv method' => sub {
    my $int = 123;
    is 0, $int->eqtv('123'); # 0; false
    is 1, $int->eqtv(123); # 1; true
};

can_ok 'Bubblegum::Object::Integer', 'format';
subtest 'test the format method' => sub {
    my $int = 500;
    is '500.00', $int->format('%.2f'); # 500.00
};


can_ok 'Bubblegum::Object::Integer', 'gt';
subtest 'test the gt method' => sub {
    my $int = 1;
    is 1, $int->gt(0); # 1; true
    is 0, $int->gt(1); # 0; false
};

can_ok 'Bubblegum::Object::Integer', 'gte';
subtest 'test the gte method' => sub {
    my $int = 1;
    is 1, $int->gte(0); # 1; true
    is 1, $int->gte(1); # 1; true
    is 0, $int->gte(2); # 0; false
};

can_ok 'Bubblegum::Object::Integer', 'lt';
subtest 'test the lt method' => sub {
    my $int = 1;
    is 1, $int->lt(2); # 1; true
    is 0, $int->lt(1); # 0; false
};

can_ok 'Bubblegum::Object::Integer', 'lte';
subtest 'test the lte method' => sub {
    my $int = 1;
    is 1, $int->lte(1); # 1; true
    is 1, $int->lte(2); # 1; true
    is 0, $int->lte(0); # 0; false
};

can_ok 'Bubblegum::Object::Integer', 'ne';
subtest 'test the ne method' => sub {
    my $int = 1;
    is 1, $int->ne(2); # 1; true
    is 0, $int->ne(1); # 0; false
};

can_ok 'Bubblegum::Object::Integer', 'to';
subtest 'test the to method' => sub {
    my $int = 5;
    is_deeply $int->to(10), [5,6,7,8,9,10]; # [5,6,7,8,9,10]
    is_deeply $int->to(0), [5,4,3,2,1,0]; # [5,4,3,2,1,0]
};

can_ok 'Bubblegum::Object::Integer', 'upto';
subtest 'test the upto method' => sub {
    my $int = 0;
    is_deeply $int->upto(10), # [0,1,2,3,4,5,6,7,8,9,10]
        [0,1,2,3,4,5,6,7,8,9,10];
};

done_testing;
