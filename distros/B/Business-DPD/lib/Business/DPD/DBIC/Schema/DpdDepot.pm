package Business::DPD::DBIC::Schema::DpdDepot;

use strict;
use warnings;

use base qw(DBIx::Class);

__PACKAGE__->load_components("Core");
__PACKAGE__->table("dpd_depot");
__PACKAGE__->add_columns(
  "depot_number",
  { data_type => "integer", is_nullable => 0, size => undef },
  "iatalikecode",
  { data_type => "text", is_nullable => 0, size => undef },
  "group_id",
  { data_type => "text", is_nullable => 0, size => undef },
  "name1",
  { data_type => "text", is_nullable => 0, size => undef },
  "name2",
  { data_type => "text", is_nullable => 0, size => undef },
  "address1",
  { data_type => "text", is_nullable => 0, size => undef },
  "address2",
  { data_type => "text", is_nullable => 0, size => undef },
  "postcode",
  { data_type => "text", is_nullable => 0, size => undef },
  "city",
  { data_type => "text", is_nullable => 0, size => undef },
  "country",
  { data_type => "text", is_nullable => 0, size => undef },
  "phone",
  { data_type => "text", is_nullable => 0, size => undef },
  "fax",
  { data_type => "text", is_nullable => 0, size => undef },
  "mail",
  { data_type => "text", is_nullable => 0, size => undef },
  "web",
  { data_type => "text", is_nullable => 0, size => undef },
);
__PACKAGE__->set_primary_key("depot_number");


# Created by DBIx::Class::Schema::Loader v0.04999_05 @ 2008-10-22 11:57:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:g3BgPjFqvL/6mPs33tuu0A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
