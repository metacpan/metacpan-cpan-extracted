use Contextual::Return;
use Test::More tests => 18;

sub bar {
    return 'in bar';
}

sub foo {
    return
        BOOL      { 0 }
        NUM       { 42 }
        LIST      { 1,2,3 }
        STR       { 'forty-two' }
        SCALAR    { 86 }
        SCALARREF { \7 }
        HASHREF   { { name => 'foo', value => 99} }
        ARRAYREF  { [3,2,1] }
        GLOBREF   { \*STDERR }
        CODEREF   { \&bar }
        RECOVER   { ok 1 => 'Recovered' }
    ;
}

package Other;
use Test::More;

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
