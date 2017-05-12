use strict;
use Test::More;
use Class::Accessor::Inherited::XS;


BEGIN {
    Class::Accessor::Inherited::XS::register_type(
        onlyr => {read_cb => sub {$_[0]}}
    );
    Class::Accessor::Inherited::XS::register_type(
        onlyw => {write_cb => sub {$_[1]}},
    );
}

use Class::Accessor::Inherited::XS
    onlyr => ['foo'],
    onlyw => ['bar'],
;

is(main->foo(42), 42);
is(main->foo, 42);

is(main->bar(42), 42);
is(main->bar, 42);

done_testing;
