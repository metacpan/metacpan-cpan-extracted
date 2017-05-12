package TestDatabase;
use strict;
use warnings;

use base qw(DBICx::TestDatabase::Subclass MySchema);

sub foo {
    return 'foo';
}

1;
