use Test::More tests => 3;
use B::Hooks::OP::Check::LeaveEval;
use lib 't/lib';

# not using cmp_ok because it calls eval

my $counter = 0;
my $id = B::Hooks::OP::Check::LeaveEval::register(sub { ++$counter });

require Foo;
ok $counter == 1, 'counter incremented by require'
    or diag "Got: $counter\nExp: 1";

eval '1';
ok $counter == 2, 'counter incremented by eval'
    or diag "Got: $counter\nExp: 2";

B::Hooks::OP::Check::LeaveEval::unregister($id);

require Bar;
eval '1';
ok $counter == 2, 'counter did not increment after unregister'
    or diag "Got: $counter\nExp: 2";
