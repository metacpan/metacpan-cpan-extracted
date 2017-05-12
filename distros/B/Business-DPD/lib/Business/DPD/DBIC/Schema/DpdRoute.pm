package Business::DPD::DBIC::Schema::DpdRoute;

use strict;
use warnings;

use base qw(DBIx::Class);

__PACKAGE__->load_components("Core");
__PACKAGE__->table("dpd_route");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    is_auto_increment => 1,
    is_nullable => 0,
    size => undef,
  },
  "dest_country",
  { data_type => "text", is_nullable => 0, size => undef },
  "begin_postcode",
  { data_type => "text", is_nullable => 0, size => undef },
  "end_postcode",
  { data_type => "text", is_nullable => 0, size => undef },
  "service_code",
  { data_type => "text", is_nullable => 0, size => undef },
  "routing_places",
  { data_type => "text", is_nullable => 0, size => undef },
  "sending_date",
  { data_type => "text", is_nullable => 0, size => undef },
  "o_sort",
  { data_type => "text", is_nullable => 0, size => undef },
  "d_depot",
  { data_type => "text", is_nullable => 0, size => undef },
  "grouping_priority",
  { data_type => "text", is_nullable => 0, size => undef },
  "d_sort",
  { data_type => "text", is_nullable => 0, size => undef },
  "barcode_id",
  { data_type => "text", is_nullable => 0, size => undef },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.04999_05 @ 2008-10-22 11:57:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Ng5lTaQRRoliiJCFpLHDKw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
