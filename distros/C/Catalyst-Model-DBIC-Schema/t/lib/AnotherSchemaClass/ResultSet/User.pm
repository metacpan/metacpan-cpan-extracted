package AnotherSchemaClass::ResultSet::User;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

__PACKAGE__->mk_group_accessors(inherited => qw/
    rs_config_option
/);

1;
