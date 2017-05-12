package
    DBIx::ParseDSN::Foo;

use Moo;
use namespace::clean;
extends 'DBIx::ParseDSN::Default';

sub i_am_a_custom_driver { return 1 }

1;
