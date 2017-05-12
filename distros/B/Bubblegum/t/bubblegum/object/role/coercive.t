use Test::More;
use Bubblegum;

ok $INC{'Bubblegum/Object/Number.pm'},
    'Bubblegum::Object::Number loaded';

ok + Bubblegum::Object::Number->DOES('Bubblegum::Object::Role::Coercive'),
    'Bubblegum::Object::Number does Bubblegum::Object::Role::Coercive';

ok $INC{'Bubblegum/Object/Hash.pm'},
    'Bubblegum::Object::Hash loaded';

ok + Bubblegum::Object::Hash->DOES('Bubblegum::Object::Role::Coercive'),
    'Bubblegum::Object::Hash does Bubblegum::Object::Role::Coercive';

ok $INC{'Bubblegum/Object/Array.pm'},
    'Bubblegum::Object::Array loaded';

ok + Bubblegum::Object::Array->DOES('Bubblegum::Object::Role::Coercive'),
    'Bubblegum::Object::Array does Bubblegum::Object::Role::Coercive';

ok $INC{'Bubblegum/Object/String.pm'},
    'Bubblegum::Object::String loaded';

ok + Bubblegum::Object::String->DOES('Bubblegum::Object::Role::Coercive'),
    'Bubblegum::Object::String does Bubblegum::Object::Role::Coercive';

ok $INC{'Bubblegum/Object/Code.pm'},
    'Bubblegum::Object::Code loaded';

ok + Bubblegum::Object::Code->DOES('Bubblegum::Object::Role::Coercive'),
    'Bubblegum::Object::Code does Bubblegum::Object::Role::Coercive';

ok $INC{'Bubblegum/Object/Undef.pm'},
    'Bubblegum::Object::Undef loaded';

ok + Bubblegum::Object::Undef->DOES('Bubblegum::Object::Role::Coercive'),
    'Bubblegum::Object::Undef does Bubblegum::Object::Role::Coercive';

subtest 'test array to array coercion via to_a' => sub {
    my $from = [ 1..4 ];
    my $to = $from->to_a;
    is_deeply $from, $to;
};

subtest 'test array to array coercion via to_array' => sub {
    my $from = [ 1..4 ];
    my $to = $from->to_array;
    is_deeply $from, $to;
};

subtest 'test array to code coercion via to_c' => sub {
    my $from = [ 1..4 ];
    my $to = $from->to_c;
    is ref $to, 'CODE';
    is_deeply $from, $to->();
};

subtest 'test array to code coercion via to_code' => sub {
    my $from = [ 1..4 ];
    my $to = $from->to_code;
    is ref $to, 'CODE';
    is_deeply $from, $to->();
};

subtest 'test array to hash coercion via to_h' => sub {
    my $from = [ 1..4 ];
    my $to = $from->to_h;
    is_deeply $to, { 1..4 };
};

subtest 'test array to hash coercion via to_hash' => sub {
    my $from = [ 1..4 ];
    my $to = $from->to_hash;
    is_deeply $to, { 1..4 };
};

subtest 'test array to number coercion via to_n' => sub {
    my $from = [ 1..4 ];
    my $to = $from->to_n;
    is $to, 4;
};

subtest 'test array to number coercion via to_number' => sub {
    my $from = [ 1..4 ];
    my $to = $from->to_number;
    is $to, 4;
};

subtest 'test array to string coercion via to_s' => sub {
    my $from = [ 1..4 ];
    my $to = $from->to_s;
    is $to, '[1,2,3,4]';
};

subtest 'test array to string coercion via to_string' => sub {
    my $from = [ 1..4 ];
    my $to = $from->to_string;
    is $to, '[1,2,3,4]';
};

subtest 'test array to undef coercion via to_u' => sub {
    my $from = [ 1..4 ];
    my $to = $from->to_u;
    is $to, undef;
};

subtest 'test array to undef coercion via to_undef' => sub {
    my $from = [ 1..4 ];
    my $to = $from->to_undef;
    is $to, undef;
};

subtest 'test code to array coercion via to_a' => sub {
    my $from = sub { "foobar" };
    my $to = $from->to_a;
    is_deeply $to, [$from];
    is $from->(), "foobar";
};

subtest 'test code to array coercion via to_array' => sub {
    my $from = sub { "foobar" };
    my $to = $from->to_array;
    is_deeply $to, [$from];
    is $from->(), "foobar";
};

subtest 'test code to code coercion via to_c' => sub {
    my $from = sub { "foobar" };
    my $to = $from->to_c;
    is ref $to, 'CODE';
    is $to->(), 'foobar';
};

subtest 'test code to code coercion via to_code' => sub {
    my $from = sub { "foobar" };
    my $to = $from->to_code;
    is ref $to, 'CODE';
    is $to->(), 'foobar';
};

subtest 'test code to hash coercion via to_h' => sub {
    my $from = sub { "foobar" };
    my $to = eval { $from->to_h };
    ok !$to;
    like $@, qr/code to hash coercion not possible/;
};

subtest 'test code to hash coercion via to_hash' => sub {
    my $from = sub { "foobar" };
    my $to = eval { $from->to_hash };
    ok !$to;
    like $@, qr/code to hash coercion not possible/;
};

subtest 'test code to number coercion via to_n' => sub {
    my $from = sub { "foobar" };
    my $to = eval { $from->to_n };
    ok !$to;
    like $@, qr/code to number coercion not possible/;
};

subtest 'test code to number coercion via to_number' => sub {
    my $from = sub { "foobar" };
    my $to = eval { $from->to_number };
    ok !$to;
    like $@, qr/code to number coercion not possible/;
};

subtest 'test code to string coercion via to_s' => sub {
    my $from = sub { "foobar" };
    my $to = eval { $from->to_s };
    ok !$to;
    like $@, qr/code to string coercion not possible/;

};

subtest 'test code to string coercion via to_string' => sub {
    my $from = sub { "foobar" };
    my $to = eval { $from->to_string };
    ok !$to;
    like $@, qr/code to string coercion not possible/;
};

subtest 'test code to undef coercion via to_u' => sub {
    my $from = sub { "foobar" };
    my $to = $from->to_u;
    is $to, undef;
};

subtest 'test code to undef coercion via to_undef' => sub {
    my $from = sub { "foobar" };
    my $to = $from->to_undef;
    is $to, undef;
};

subtest 'test hash to array coercion via to_a' => sub {
    my $from = { 1..4 };
    my $to = $from->to_a;
    is_deeply $to, [{1..4}];
};

subtest 'test hash to array coercion via to_array' => sub {
    my $from = { 1..4 };
    my $to = $from->to_array;
    is_deeply $to, [{1..4}];
};

subtest 'test hash to code coercion via to_c' => sub {
    my $from = { 1..4 };
    my $to = $from->to_c;
    is ref $to, 'CODE';
    is_deeply $to->(), {1..4};
};

subtest 'test hash to code coercion via to_code' => sub {
    my $from = { 1..4 };
    my $to = $from->to_code;
    is ref $to, 'CODE';
    is_deeply $to->(), {1..4};
};

subtest 'test hash to hash coercion via to_h' => sub {
    my $from = { 1..4 };
    my $to = $from->to_h;
    is_deeply $from, $to;
};

subtest 'test hash to hash coercion via to_hash' => sub {
    my $from = { 1..4 };
    my $to = $from->to_hash;
    is_deeply $from, $to;
};

subtest 'test hash to number coercion via to_n' => sub {
    my $from = { 1..4 };
    my $to = $from->to_n;
    is $to, 2;
};

subtest 'test hash to number coercion via to_number' => sub {
    my $from = { 1..4 };
    my $to = $from->to_number;
    is $to, 2;
};

subtest 'test hash to string coercion via to_s' => sub {
    my $from = { 1..4 };
    my $to = $from->to_s;
    is $to, "{'1' => 2,'3' => 4}";
};

subtest 'test hash to string coercion via to_string' => sub {
    my $from = { 1..4 };
    my $to = $from->to_string;
    is $to, "{'1' => 2,'3' => 4}";
};

subtest 'test hash to undef coercion via to_u' => sub {
    my $from = { 1..4 };
    my $to = $from->to_u;
    is $to, undef;
};

subtest 'test hash to undef coercion via to_undef' => sub {
    my $from = { 1..4 };
    my $to = $from->to_undef;
    is $to, undef;
};

subtest 'test number to array coercion via to_a' => sub {
    my $from = 12345;
    my $to = $from->to_a;
    is_deeply $to, [$from];
};

subtest 'test number to array coercion via to_array' => sub {
    my $from = 12345;
    my $to = $from->to_array;
    is_deeply $to, [$from];
};

subtest 'test number to code coercion via to_c' => sub {
    my $from = 12345;
    my $to = $from->to_c;
    is ref $to, 'CODE';
    is $to->(), $from;
};

subtest 'test number to code coercion via to_code' => sub {
    my $from = 12345;
    my $to = $from->to_code;
    is ref $to, 'CODE';
    is $to->(), $from;
};

subtest 'test number to hash coercion via to_h' => sub {
    my $from = 12345;
    my $to = $from->to_h;
    is_deeply $to, {$from => 1};
};

subtest 'test number to hash coercion via to_hash' => sub {
    my $from = 12345;
    my $to = $from->to_hash;
    is_deeply $to, {$from => 1};
};

subtest 'test number to number coercion via to_n' => sub {
    my $from = 12345;
    my $to = $from->to_n;
    is $to, $from;
};

subtest 'test number to number coercion via to_number' => sub {
    my $from = 12345;
    my $to = $from->to_number;
    is $to, $from;
};

subtest 'test number to string coercion via to_s' => sub {
    my $from = 12345;
    my $to = $from->to_s;
    is $to, "$from";
};

subtest 'test number to string coercion via to_string' => sub {
    my $from = 12345;
    my $to = $from->to_string;
    is $to, "$from";
};

subtest 'test number to undef coercion via to_u' => sub {
    my $from = 12345;
    my $to = $from->to_u;
    is $to, undef;
};

subtest 'test number to undef coercion via to_undef' => sub {
    my $from = 12345;
    my $to = $from->to_undef;
    is $to, undef;
};

subtest 'test string to array coercion via to_a' => sub {
    my $from = "foobar";
    my $to = $from->to_a;
    is_deeply $to, [$from];
};

subtest 'test string to array coercion via to_array' => sub {
    my $from = "foobar";
    my $to = $from->to_array;
    is_deeply $to, [$from];
};

subtest 'test string to code coercion via to_c' => sub {
    my $from = "foobar";
    my $to = $from->to_c;
    is ref $to, 'CODE';
    is $to->(), $from;
};

subtest 'test string to code coercion via to_code' => sub {
    my $from = "foobar";
    my $to = $from->to_code;
    is ref $to, 'CODE';
    is $to->(), $from;
};

subtest 'test string to hash coercion via to_h' => sub {
    my $from = "foobar";
    my $to = $from->to_h;
    is_deeply $to, {$from => 1};
};

subtest 'test string to hash coercion via to_hash' => sub {
    my $from = "foobar";
    my $to = $from->to_hash;
    is_deeply $to, {$from => 1};
};

subtest 'test string to number coercion via to_n' => sub {
    my $from = "foobar";
    my $to = $from->to_n;
    is $to, 0;
};

subtest 'test string to number coercion via to_number' => sub {
    my $from = "foobar";
    my $to = $from->to_number;
    is $to, 0;
};

subtest 'test string to string coercion via to_s' => sub {
    my $from = "foobar";
    my $to = $from->to_s;
    is $to, $from;
};

subtest 'test string to string coercion via to_string' => sub {
    my $from = "foobar";
    my $to = $from->to_string;
    is $to, $from;
};

subtest 'test string to undef coercion via to_u' => sub {
    my $from = "foobar";
    my $to = $from->to_u;
    is $to, undef;
};

subtest 'test string to undef coercion via to_undef' => sub {
    my $from = "foobar";
    my $to = $from->to_undef;
    is $to, undef;
};

subtest 'test undef to array coercion via to_a' => sub {
    my $from = undef;
    my $to = $from->to_a;
    is_deeply $to, [undef];
};

subtest 'test undef to array coercion via to_array' => sub {
    my $from = undef;
    my $to = $from->to_array;
    is_deeply $to, [undef];
};

subtest 'test undef to code coercion via to_c' => sub {
    my $from = undef;
    my $to = $from->to_c;
    is ref $to, 'CODE';
    is $to->(), undef;
};

subtest 'test undef to code coercion via to_code' => sub {
    my $from = undef;
    my $to = $from->to_code;
    is ref $to, 'CODE';
    is $to->(), undef;
};

subtest 'test undef to hash coercion via to_h' => sub {
    my $from = undef;
    my $to = $from->to_h;
    is_deeply $to, {};
};

subtest 'test undef to hash coercion via to_hash' => sub {
    my $from = undef;
    my $to = $from->to_hash;
    is_deeply $to, {};
};

subtest 'test undef to number coercion via to_n' => sub {
    my $from = undef;
    my $to = $from->to_n;
    is $to, 0;
};

subtest 'test undef to number coercion via to_number' => sub {
    my $from = undef;
    my $to = $from->to_number;
    is $to, 0;
};

subtest 'test undef to string coercion via to_s' => sub {
    my $from = undef;
    my $to = $from->to_s;
    is $to, '';
};

subtest 'test undef to string coercion via to_string' => sub {
    my $from = undef;
    my $to = $from->to_string;
    is $to, '';
};

subtest 'test undef to undef coercion via to_u' => sub {
    my $from = undef;
    my $to = $from->to_u;
    is $to, undef;
};

subtest 'test undef to undef coercion via to_undef' => sub {
    my $from = undef;
    my $to = $from->to_undef;
    is $to, undef;
};

done_testing;
