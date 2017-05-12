package DBSchema::Result::Twokeys;

# Created by DBIx::Class::Schema::Loader v0.03000 @ 2006-10-02 08:24:09

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("PK::Auto", "Core");
__PACKAGE__->table("twokeys");
__PACKAGE__->add_columns(
    "dvd_name" => { data_type => 'varchar', size => 100 },
    "key2" => { data_type => 'integer' },
);
__PACKAGE__->set_primary_key("dvd_name", "key2");

__PACKAGE__->add_relationship('like_belongs_to', 'DBSchema::Result::Dvd', { 'foreign.name' => 'self.dvd_name' }, { accessor => 'single' });


1;