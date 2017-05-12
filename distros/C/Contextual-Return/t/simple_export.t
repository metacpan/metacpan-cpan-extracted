use Contextual::Return qr{BOOL|LIST|NUM};

sub bar {
    return 'in bar';
}

sub foo {
    return
        BOOL      { 0 }
        LIST      { 1,2,3 }
        NUM       { 42 }
    ;
}

package Other;
use Test::More 'no_plan';

is_deeply [ ::foo() ], [1,2,3]                  => 'LIST context';

is do{ ::foo() ? 'true' : 'false' }, 'false'    => 'BOOLEAN context';

is 0+::foo(), 42                                => 'NUMERIC context';

no warnings 'once';

ok ! *main::STR{CODE}                           => 'No STRING context';
ok ! *main::SCALAR{CODE}                        => 'No SCALAR context';   
ok ! *main::SCALARREF{CODE}                     => 'No SCALARREF context';
ok ! *main::HASHREF{CODE}                       => 'No HASHREF context';  
ok ! *main::ARRAYREF{CODE}                      => 'No ARRAYREF context';
ok ! *main::GLOBREF{CODE}                       => 'No GLOBREF context';  
ok ! *main::CODEREF{CODE}                       => 'No CODEREF context';  
