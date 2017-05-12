package My::Schema;
our $VERSION = '0.002';

use strict;
use warnings;
use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;

1;
