use utf8;
package t::lib::Schema1::Result::User;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table("users");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "login_name",
  { data_type => "text", is_nullable => 0 },
  "passphrase",
  { data_type => "text", is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 1 },
  "activated",
  { data_type => "integer", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->add_unique_constraint("login_name_unique", ["login_name"]);

__PACKAGE__->has_many(
  "memberships",
  "t::lib::Schema1::Result::Membership",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

1;
