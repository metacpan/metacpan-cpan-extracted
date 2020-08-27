package DBSchema::Result::Dvdtag;

# Created by DBIx::Class::Schema::Loader v0.03000 @ 2006-10-02 08:24:09

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("PK::Auto", "Core");
__PACKAGE__->table("dvdtag");
__PACKAGE__->add_columns(
    "dvd" => { data_type => 'integer' },
    "tag" => { data_type => 'integer' },
);
__PACKAGE__->set_primary_key("dvd", "tag");
__PACKAGE__->belongs_to("dvd", "DBSchema::Result::Dvd", { dvd_id => "dvd" });
__PACKAGE__->belongs_to("tag", "DBSchema::Result::Tag", { id => "tag" });
# same relationship with a name that's different from the column name
__PACKAGE__->belongs_to("rel_tag", "DBSchema::Result::Tag", { id => "tag" });

1;
