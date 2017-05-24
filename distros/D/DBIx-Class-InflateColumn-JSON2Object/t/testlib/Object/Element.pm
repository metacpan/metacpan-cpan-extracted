package testlib::Object::Element;
use 5.010;
use Moose;
with 'DBIx::Class::InflateColumn::JSON2Object::Role::Storable';

has 'text' => (
    is=>'ro',
    isa=>'Str',
);

__PACKAGE__->meta->make_immutable;
