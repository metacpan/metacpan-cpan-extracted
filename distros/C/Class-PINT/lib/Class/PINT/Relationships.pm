package Class::PINT::Relationships;

use strict;

use base qw(Class::DBI);


# IsA stuff
__PACKAGE__->add_relationship_type(is_a => 'Class::DBI::Relationship::IsA');


################################################################################

1;
