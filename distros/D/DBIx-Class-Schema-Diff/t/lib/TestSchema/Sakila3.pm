package # Hide from pause
     TestSchema::Sakila3;

# Same as TestSchema::Sakila but with misc changes...
use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;

# find . -type f -exec sed -i 's/Sakila2/Sakila3/g' {} \;

1;
