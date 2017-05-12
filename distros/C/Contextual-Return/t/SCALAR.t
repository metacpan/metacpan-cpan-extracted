use Contextual::Return;
use Test::More 'no_plan';

sub foo {
    return
        SCALAR   { 86 }
        VALUE    { 42, 99 }
}

is_deeply \@{foo()}, [42,99]                    => 'ARRAYREF from NONVOID';
is ${foo()}+0, 86                               => 'NUMERIC from SCALAR';
is "${foo()}", '86'                             => 'STRING from SCALAR';
is "@{foo()}", '42 99'                          => 'STRING from NONVOID';
