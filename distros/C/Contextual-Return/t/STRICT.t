use Contextual::Return;

sub bar {
    return 'in bar';
}

sub foo {
    return STRICT
        PUREBOOL  { 1 }
        BOOL      { 0 }
        LIST      { 1,2,3 }
        NUM       { 42 }
        STR       { 'forty-two' }
        REF       { [] }
        DEFAULT   { {} }
    ;
}

package Other;
use Test::More 'no_plan';

is_deeply [ ::foo() ], [1,2,3]                         => 'LIST context';

is do{ ::foo() ? 'true' : 'false' }, 'true'            => 'PURE BOOLEAN context';

is do{ (my $x = ::foo()) ? 'true' : 'false' }, 'false' => 'BOOLEAN context';

is 0+::foo(), 42                                       => 'NUMERIC context';

is "".::foo(), 'forty-two'                             => 'STRING context';

ok !eval { ::foo(); 1 }                                => 'No VOID context';
like $@, qr{Can't call main::foo in a void context}    => '...with correct error msg';

ok !eval { my $scalar = ${::foo()}; 1 }                => 'No SCALARREF context';
like $@, qr{Call to main::foo didn't return a scalar reference, as required} => '...with correct error msg';

ok !eval { my @list = @{::foo()}; 1 }                             => 'No ARRAYREF context';
like $@, qr{Call to main::foo didn't return an array reference, as required} => '...with correct error msg';

ok !eval { my %hash = %{::foo()}; 1 }                             => 'No HASHREF context';
like $@, qr{Call to main::foo didn't return a hash reference, as required}   => '...with correct error msg';
