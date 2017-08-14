use strict;
use Test::More;
use parent 'Class::Accessor::Inherited::XS::Compat';

BEGIN {
    is Class::Accessor::Inherited::XS::is_type_registered('sone'), '';
    Class::Accessor::Inherited::XS::register_types(
        sone => {read_cb => sub {shift() + 1}},
        stwo => {read_cb => sub {shift() + 2}},
    );
    is Class::Accessor::Inherited::XS::is_type_registered('sone'), 1;
}

use Class::Accessor::Inherited::XS
    sone => ['foo'],
    stwo => ['bar'],
;

is(main->foo, 1);
is(main->bar, 2);

__PACKAGE__->mk_type_accessors(stwo => 'baz');
is(main->baz, 2);

done_testing;
