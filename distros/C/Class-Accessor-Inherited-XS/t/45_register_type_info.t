use strict;
use Test::More;
use Class::Accessor::Inherited::XS;

my $type;
my $counter = 0;

sub wrt { is my $foo = $_[-1], $type; ++$counter; $_[1] }
sub rdt { is my $foo = $_[-1], $type; ++$counter; $_[0] }

sub foo {}

BEGIN {
    Class::Accessor::Inherited::XS::register_types(
        nmd => {write_cb => \&wrt, read_cb => \&rdt, opts => 4},
        stb => {write_cb => \&foo, read_cb => \&foo},
    );
}

use Class::Accessor::Inherited::XS
    nmd       => ['bar', 'baz'],
    stb       => 'stb',
    inherited => 'inh',
;

my $obj = bless {};

for my $arg (1, 2, 100, 500) {
    {
        $type = 'bar';

        my $blah = $obj->bar(($arg) x $arg);
        is $blah, $arg;

        is $obj->bar, $arg;
        is $obj->$type, $arg;
    }

    {
        $type = 'baz';

        my $blah = $obj->baz(($arg) x $arg);
        is $blah, $arg;

        is $obj->baz, $arg;
        is $obj->$type, $arg;
    }
}

for (1..2) {
    for my $meth (qw/stb inh/) {
        $obj->$meth(42);
        $obj->$meth;
    }
}

is $counter, 4 * 2 * 3; # arg - type - w/r/r
is(Class::Accessor::Inherited::XS::Debug::unstolen_count(), Class::Accessor::Inherited::XS::OPTIMIZED_OPMETHOD ? 0 : 2);

done_testing;
