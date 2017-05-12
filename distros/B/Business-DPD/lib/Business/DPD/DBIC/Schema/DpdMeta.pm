package Business::DPD::DBIC::Schema::DpdMeta;

use strict;
use warnings;

use base qw(DBIx::Class);

__PACKAGE__->load_components("Core");
__PACKAGE__->table("dpd_meta");
__PACKAGE__->add_columns(
  "version",
  { data_type => "integer", is_nullable => 0, size => undef },
  "expires",
  { data_type => "text", is_nullable => 0, size => undef },
  "reference",
  { data_type => "text", is_nullable => 0, size => undef },
);
__PACKAGE__->set_primary_key("version");


# Created by DBIx::Class::Schema::Loader v0.04999_05 @ 2008-10-22 11:57:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/H6ehAOUhvhPlr4QOcVT8Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
