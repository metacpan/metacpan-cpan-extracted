package Foo::Result::User;
use base 'DBIx::Class::Core';
use strict;
use warnings;

__PACKAGE__->table("user");
__PACKAGE__->add_columns(
  name => { data_type => "varchar", is_nullable => 0, size => 100 },
  age  => { data_type => "int", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("name");

1;
