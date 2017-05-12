use Bubblegum;
use Test::More;

ok ! main->isa('Moo::Object'), 'class not an object';

can_ok 'Bubblegum::Object::Code', 'call';
subtest 'test the call method' => sub {
    my $code = sub { (shift // 0) + 1 };
    is 1, $code->call; # 1
    is 1, $code->call(0); # 1
    is 2, $code->call(1); # 2
    is 3, $code->call(2); # 3
};

can_ok 'Bubblegum::Object::Code', 'curry';
subtest 'test the curry method' => sub {
    my $code = sub { [@_] };
    is 'CODE', ref($code = $code->curry(1,2,3));
    is_deeply $code->(4,5,6), [1,2,3,4,5,6]; # [1,2,3,4,5,6]
};

can_ok 'Bubblegum::Object::Code', 'rcurry';
subtest 'test the rcurry method' => sub {
    my $code = sub { [@_] };
    is 'CODE', ref($code = $code->rcurry(1,2,3));
    is_deeply $code->(4,5,6), [4,5,6,1,2,3]; # [4,5,6,1,2,3]
};

can_ok 'Bubblegum::Object::Code', 'compose';
subtest 'test the compose method' => sub {
    my $code = sub { [@_] };
    is 'CODE', ref($code = $code->compose($code, 1,2,3));
    is_deeply $code->(4,5,6), [[1,2,3,4,5,6]]; # [[1,2,3,4,5,6]]
};

can_ok 'Bubblegum::Object::Code', 'disjoin';
subtest 'test the disjoin method' => sub {
    my $code = sub { $_[0] % 2 };
    is 'CODE', ref($code = $code->disjoin(sub { -1 }));
    is -1, $code->(0); # -1
    is 1, $code->(1); #  1
    is -1, $code->(2); # -1
    is 1, $code->(3); #  1
    is -1, $code->(4); # -1
};

can_ok 'Bubblegum::Object::Code', 'conjoin';
subtest 'test the conjoin method' => sub {
    my $code = sub { $_[0] % 2 };
    is 'CODE', ref($code = $code->conjoin(sub { 1 }));
    is 0, $code->(0); # 0
    is 1, $code->(1); # 1
    is 0, $code->(2); # 0
    is 1, $code->(3); # 1
    is 0, $code->(4); # 0
};

can_ok 'Bubblegum::Object::Code', 'next';
subtest 'test the next method' => sub {
    my $code = sub { (shift // 0) + 1 };
    is 1, $code->next; # 1
    is 1, $code->next(0); # 1
    is 2, $code->next(1); # 2
    is 3, $code->next(2); # 3
};

can_ok 'Bubblegum::Object::Code', 'print';
subtest 'test the print method' => sub {
    my $code = sub{''};
    is 1, $code->print; # ''
    is 1, $code->print(''); # ''
};

can_ok 'Bubblegum::Object::Code', 'say';
subtest 'test the say method' => sub {
    my $code = sub{''};
    is 1, $code->say; # ''
    is 1, $code->say(''); # ''
};

done_testing;
