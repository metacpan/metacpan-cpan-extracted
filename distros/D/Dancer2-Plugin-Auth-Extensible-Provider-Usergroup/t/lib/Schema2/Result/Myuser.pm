use utf8;
package t::lib::Schema2::Result::Myuser;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("myusers");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "mylogin_name",
  { data_type => "text", is_nullable => 0 },
  "mypassphrase",
  { data_type => "text", is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 1 },
  "myactivated",
  { data_type => "integer", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint("mylogin_name_unique", ["mylogin_name"]);

__PACKAGE__->has_many(
  "mymemberships",
  "t::lib::Schema2::Result::Mymembership",
  { "foreign.myuser_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
1;
