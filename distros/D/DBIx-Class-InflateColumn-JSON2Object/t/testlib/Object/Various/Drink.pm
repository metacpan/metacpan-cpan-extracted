package testlib::Object::Various::Drink;
use 5.010;
use Moose;
extends 'testlib::Object::Various';

has 'alcoholic' => (
    is=>'ro',
    isa=>'InflateColumnJSONBool',
    coerce=>1,
);

__PACKAGE__->meta->make_immutable;
