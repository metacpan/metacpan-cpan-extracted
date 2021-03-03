use strict;
use warnings;
use lib 't/lib';
use Test::More;

use Boundary::Types -types;

{
    # case: OK
    package Foo;
    use Boundary::Impl qw(IFoo);
    sub hello;
    sub new { bless {} => $_[0] }
}

{
    # case: NG
    package Bar;
    use Boundary::Impl qw(IBar);
    sub world;
    sub new { bless {} => $_[0] }
}

{
    # case: NG
    package Baz;
    sub new { bless {} => $_[0] }
}

{
    # case: NG
    package Qux;
    sub hello;
    sub new { bless {} => $_[0] }
}

{
    # case: NG
    package Quux;
    sub hello;
}

my $type = ImplOf['IFoo'];
isa_ok $type, 'Type::Tiny';
is $type->display_name, 'ImplOf[IFoo]';

ok $type->check(Foo->new);
ok !$type->check(Bar->new);
ok !$type->check(Baz->new);
ok !$type->check(Qux->new);
ok !$type->check('Quux'), 'ClassName not pass';

done_testing;
