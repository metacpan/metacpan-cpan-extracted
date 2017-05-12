use Contextual::Return;
use Test::More 'no_plan';
use Carp;

sub foo {
    return
        NONVOID { 4.2, 9.9 }
        VOID    { die 'Useless use of foo() in void context' }
    ;
}

# and later...

$foo = foo();
ok $foo                            => 'BOOLEAN context';

is 0+$foo, 9.9                     => 'NUMERIC context';

is "$foo", 9.9                     => 'STRING context';

is join(q{,}, foo()), '4.2,9.9'    => 'LIST context';

my $res = eval{ ;foo(); 1; };
my $exception = $@;

ok !$res                           => 'VOID context fails';

like $exception, qr/\QUseless use of foo() in void context/
                                   => 'Error msg correct';
