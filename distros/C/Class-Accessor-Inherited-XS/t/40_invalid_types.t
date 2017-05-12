use strict;
use Test::More;
use Class::Accessor::Inherited::XS;

Class::Accessor::Inherited::XS::register_type('foo', {});
eval { Class::Accessor::Inherited::XS::register_type('foo', {}) };
like $@, qr/already/;

eval { Class::Accessor::Inherited::XS->import(
    component => ['foo'],
)};
like $@, qr/install 'component' accessors/;

done_testing;
