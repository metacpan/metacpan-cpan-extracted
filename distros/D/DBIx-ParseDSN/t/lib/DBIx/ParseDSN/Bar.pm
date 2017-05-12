package
    DBIx::ParseDSN::Bar;

use Moo;
extends "DBIx::ParseDSN::Default";
use namespace::clean;

sub i_am_also_a_custom_driver { return 1 }

1;
