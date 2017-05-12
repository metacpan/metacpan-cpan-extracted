use Contextual::Return
        qr{},
        BOOL   => BOOLEAN,
        LIST   => VECTOR,
        NUM    => NUMERIC,
        STR    => STRINGIFIC,
        SCALAR => SINGULAR,
;

sub bar {
    return 'in bar';
}

sub foo {
    return
        BOOLEAN    { 0 }
        VECTOR     { 1,2,3 }
        NUMERIC    { 42 }
        STRINGIFIC { 'forty-two' }
        SINGULAR   { 86 }
        SCALARREF  { \7 }
        HASHREF    { { name => 'foo', value => 99} }
        ARRAYREF   { [3,2,1] }
        GLOBREF    { \*STDERR }
        CODEREF    { \&bar }
    ;
}

package Other;
use Test::More 'no_plan';

is_deeply [ ::foo() ], [1,2,3]                  => 'LIST context';

is do{ ::foo() ? 'true' : 'false' }, 'false'    => 'BOOLEAN context';

is 0+::foo(), 42                                => 'NUMERIC context';

is "".::foo(), 'forty-two'                      => 'STRING context';

is ${::foo}, 7                                  => 'SCALARREF context';

is_deeply \%{::foo()},
          { name => 'foo', value => 99}         => 'HASHREF context';

is_deeply \@{::foo()}, [3,2,1]                  => 'ARRAYREF context';

is \*{::foo()}, \*STDERR                        => 'GLOBREF context';

is ::foo->(), 'in bar'                          => 'ARRAYREF context';
