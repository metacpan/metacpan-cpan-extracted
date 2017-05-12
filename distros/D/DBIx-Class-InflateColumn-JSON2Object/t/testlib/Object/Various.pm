package testlib::Object::Various;
use 5.010;
use Moose;
with 'DBIx::Class::InflateColumn::JSON2Object::Role::Storable';

has 'name' => (
    is=>'ro',
    isa=>'Str',
);

__PACKAGE__->meta->make_immutable;
