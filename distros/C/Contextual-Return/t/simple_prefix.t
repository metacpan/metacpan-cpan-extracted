use Contextual::Return qr{.+} => 'ANTE_%s';

sub bar {
    return 'in bar';
}

sub foo {
    return
        ANTE_BOOL      { 0 }
        ANTE_LIST      { 1,2,3 }
        ANTE_NUM       { 42 }
        ANTE_STR       { 'forty-two' }
        ANTE_SCALAR    { 86 }
        ANTE_SCALARREF { \7 }
        ANTE_HASHREF   { { name => 'foo', value => 99} }
        ANTE_ARRAYREF  { [3,2,1] }
        ANTE_GLOBREF   { \*STDERR }
        ANTE_CODEREF   { \&bar }
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
