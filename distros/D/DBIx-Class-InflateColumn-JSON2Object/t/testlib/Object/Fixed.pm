package testlib::Object::Fixed;
use 5.010;
use Moose;
with 'DBIx::Class::InflateColumn::JSON2Object::Role::Storable';

has 'text' => (
    is=>'ro',
    isa=>'Str',
);

has 'amount' => (
    is=>'ro',
    isa=>'Int',
);

has 'more' => (
    is=>'ro',
    isa=>'HashRef',
);

has 'flag' => (
    is=>'ro',
    isa=>'InflateColumnJSONBool',
    coerce=>1,
);

__PACKAGE__->meta->make_immutable;
