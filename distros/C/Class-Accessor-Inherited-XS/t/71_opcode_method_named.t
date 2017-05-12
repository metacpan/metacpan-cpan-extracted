use Test::More;
use Class::Accessor::Inherited::XS;
use strict;

{
    package Jopa;
    use Class::Accessor::Inherited::XS {
        inherited => [qw/a/],
        class     => [qw/b/],
    };

    sub new { return bless {}, shift }
    sub foo { 42 }
}

{
    package JopaChild;
    our @ISA = qw/Jopa/;
}

{
    package Other;
    sub new { return bless {}, shift }
    sub a { 123 }
}

{
    package JopaClass;
    use Class::Accessor::Inherited::XS class => [qw/a/];

    sub new { return bless {}, shift }
}

my $o = new Jopa;
$o->{a} = 1;

for (1..3) {
    is($o->a, 1);
}

for (1..3) {
    is($o->a(6), 6);
}

my $u = new Jopa;
Jopa->a(40);
$u->a(50);

my $n = new Other;

my @res = (6, 6, 50, 6, 123, 6);
for ($o, $o, $u, $o, $n, $o) {
    is($_->a, shift @res);
}

@res = (40, 40, 123, 40);
for ('Jopa', 'Jopa', 'Other', 'Jopa') {
    is($_->a, shift @res);
}

my $jc = new JopaClass;
$jc->{a} = 77;
JopaClass->a(70);

@res = (6, 6, 70, 6);
for ($o, $o, $jc, $o) {
    is($_->a, shift @res);
}

@res = (40, 40, 70, 6);
for ('Jopa', 'Jopa', 'JopaClass', $o) {
    is($_->a, shift @res);
}

*main::a = *JopaClass::a;

__PACKAGE__->a; # adds 'main' to package cache for < 5.22

@res = (40, 40, 70, 6);
for ('Jopa', 'Jopa', __PACKAGE__, $o) {
    is($_->a, shift @res);
}

@res = (40, 40, 6);
for ('Jopa', 'Jopa', \12, $o) {
    eval { is($_->a, shift @res) };
}

@res = (40, 40, 40, 40, 40);
for ('Jopa', 'Jopa', 'JopaChild', 'Jopa', 'JopaChild') {
    is($_->a, shift @res);
}

Jopa->b(80);
@res = (40, 80);
for (qw/a b/) {
    is(Jopa->$_, shift @res);
}

is(Class::Accessor::Inherited::XS::_unstolen_count, Class::Accessor::Inherited::XS::OPTIMIZED_OPMETHOD ? 5 : 6);

done_testing;
