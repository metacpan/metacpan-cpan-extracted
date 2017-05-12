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
        SCALARREF { \7 }
        HASHREF   { { name => 'foo', value => 99} }
        ARRAYREF  { [3,2,1] }
        GLOBREF   { \*STDERR }
        CODEREF   { \&bar }
        CLEANUP   { Other::ok(1 => 'CLEANUP') }
    ;
}

package Other;
use Test::More tests=>27;

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

$foo = ::foo();

is ${$foo}, 7                                  => 'SCALARREF via var';

$foo = undef;

my ($void, $tested);
sub side_effect {
    use Contextual::Return;
    return 
        BOOL { $tested = 1 }
        VOID { $void   = 1 }
        CLEANUP { $_ = 42 if $tested }
};

side_effect();

is $void, 1     => 'SIDE EFFECT VOID';
ok !defined $_  => 'NO ASSIGNMENT TO $_';

undef $void;

my $side_effect   = side_effect();
ok !defined $void => 'SIDE EFFECT NONVOID';
ok !defined $_    => 'NO ASSIGNMENT TO $_';

ok side_effect()  => 'SIDE EFFECT BOOLEAN';
ok !defined $void => 'SIDE EFFECT BOOLEAN NONVOID';
is $_, 42         => 'ASSIGNMENT TO $_';
