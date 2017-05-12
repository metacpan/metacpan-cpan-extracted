package Schema1::Result::User;

use strict;
use warnings;
use base qw/DBIx::Class::Core/;


__PACKAGE__->table("user");

__PACKAGE__->add_columns(
      "user_id",	{ data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
      "first_name", { data_type => "varchar2", is_nullable => 0, size => 45 },
      "last_name", { data_type => "varchar2", is_nullable => 0, size => 45 },
      "permission_type_id", { data_type => "integer", is_nullable => 0 },
);


__PACKAGE__->set_primary_key("user_id");


1;
