use strict;
use lib 'lib', 't/lib';

use ContactSchema;
use AutoCode::ObjectFactory;


my $schema = ContactSchema->new();

my $factory = AutoCode::ObjectFactory->new(
    -schema => $schema
);

my $person=$factory->get_instance('Person',
    -first_name => 'Juguang',
    -last_name => 'XIAO',
    -emails => []
);

print $person->can('first_name'), "\n";
print $person->can('last_name'), "\n";
print $person->first_name, "\t", $person->last_name, "\n";
