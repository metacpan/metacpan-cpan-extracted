use Contextual::Return;

sub bar {
    return 'in bar';
}

sub foo {
    return
        BOOL      { 0 }
        LIST      { 1,2,3 }
        NUM       { 42 }
        STR       { 'forty-two' }
        SCALAR    { 86 }
        RECOVER   { RESULT { wantarray ? 1..9 : 99 } }
    ;
}

package Other;
use Test::More qw< no_plan >;

is_deeply [ ::foo() ], [1..9]                  => 'LIST context';

is do{ ::foo() ? 'true' : 'false' }, 'true'    => 'BOOLEAN context';

is 0+::foo(), 99                                => 'NUMERIC context';

is "".::foo(), '99'                             => 'STRING context';
