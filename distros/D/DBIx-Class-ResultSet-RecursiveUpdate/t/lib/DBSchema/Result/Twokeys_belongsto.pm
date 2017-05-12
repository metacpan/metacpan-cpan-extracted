package DBSchema::Result::Twokeys_belongsto;

# Created by DBIx::Class::Schema::Loader v0.03000 @ 2006-10-02 08:24:09

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("PK::Auto", "Core");
__PACKAGE__->table("twokeys_belongsto");
__PACKAGE__->add_columns(
    "key1" => { data_type => 'integer' },
    "key2" => { data_type => 'integer' },
);
__PACKAGE__->set_primary_key("key1", "key2");

__PACKAGE__->add_relationship('like_belongs_to', 'DBSchema::Result::Dvd', { 'foreign.twokeysfk' => 'self.key1' }, );

__PACKAGE__->belongs_to('onekey', 'DBSchema::Result::Onekey', { 'foreign.id' => 'self.key1' }, );


1;