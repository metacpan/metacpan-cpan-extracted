package testlib::Object::Various::Food;
use 5.010;
use Moose;
extends 'testlib::Object::Various';

has 'vegetarian' => (
    is=>'ro',
    isa=>'InflateColumnJSONBool',
    coerce=>1,
);

__PACKAGE__->meta->make_immutable;
