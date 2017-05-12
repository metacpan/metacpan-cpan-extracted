package Person;
use warnings;
use strict;
use parent 'Class::Accessor::FactoryTyped';
__PACKAGE__->mk_factory_typed_accessors(
    'MyFactory',
    person_name    => 'name',
    person_address => 'address',
);

__PACKAGE__->mk_factory_typed_array_accessors(
    'MyFactory',
    person_name => 'friends',
);
1;
