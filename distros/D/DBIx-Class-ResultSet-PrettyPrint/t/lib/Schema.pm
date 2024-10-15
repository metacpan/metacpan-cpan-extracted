package # hide from PAUSE
    Schema;

# the trick to hide this tests-only package was copied from
# https://github.com/davidolrik/DBIx-Class-FormTools

use 5.010;
use strict;
use warnings;

use base qw(DBIx::Class::Schema);

__PACKAGE__->load_namespaces();

1;

# vim: expandtab shiftwidth=4
