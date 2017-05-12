use strict;
use Test::More;

my $foo = 12;

use Class::Accessor::Inherited::XS {
    class_ro    => {
        foo => sub {++$foo},
        bar => sub {},
        baz => sub {40,41,42},
    },
    class       => {
        boo => sub {78},
    },
    varclass    => {
        zoo => sub {55},
        moo => sub {98},
    },
};

sub exception (&) {
    $@ = undef;
    eval { shift->() };
    $@
}

for (1..2) {
    is(__PACKAGE__->foo, 13);
    like exception {__PACKAGE__->foo(67)}, qr/^Can't set/;
    is(__PACKAGE__->foo, 13);

    is($foo, 13);
}

is(__PACKAGE__->bar, undef) for (1..3);

like exception {__PACKAGE__->baz(67)}, qr/^Can't set/;
is(__PACKAGE__->baz, 42) for (1..3);

is(__PACKAGE__->boo(90), 90);
is(__PACKAGE__->boo, 90) for (1..3);

is(__PACKAGE__->zoo, 55) for (1..3);
is(__PACKAGE__->zoo(70), 70);
is(__PACKAGE__->zoo, 70);

my $ref = \(__PACKAGE__->moo);
is($$ref, 98);
$$ref = 17;
is(__PACKAGE__->moo, 17);

is(Class::Accessor::Inherited::XS::_unstolen_count, 0);

done_testing;
