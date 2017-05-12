package # Hide from pause
     TestSchema::Sakila2;

# Same as TestSchema::Sakila but with a different class name...
use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


1;
