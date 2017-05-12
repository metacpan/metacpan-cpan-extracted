package DBIx::Class::Schema::Config::ConfigFiles::Hash;
use strict;
use warnings;
use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("hash");
__PACKAGE__->add_columns(
  "key",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "value",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
);
__PACKAGE__->add_unique_constraint("key_unique", ["key"]);
1;
