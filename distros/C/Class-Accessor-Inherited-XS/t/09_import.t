use strict;
use Test::More;

{
    package Jopa;
    use Class::Accessor::Inherited::XS inherited => {
        foo => 'bar',
    };

    sub new { return bless {}, shift }
}

{
    package NewJopa;
    use Class::Accessor::Inherited::XS {
        package   => 'Jopa',
        inherited => [qw/boo baz/],
    };
}

my $o = Jopa->new;
$o->{bar} = 1;
is($o->foo, 1);

is($o->boo(12), 12);
is($o->baz(10), 10);

is(NewJopa->can('boo'), undef);

done_testing;
