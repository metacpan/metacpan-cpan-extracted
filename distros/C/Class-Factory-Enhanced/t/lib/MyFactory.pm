package MyFactory;
use warnings;
use strict;
use parent 'Class::Factory::Enhanced';

# Default mappings
__PACKAGE__->register_factory_type(
    person_name    => 'Person::SimpleName',
    person_address => 'Person::SimpleAddress',
);
1;
