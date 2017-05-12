package DBSchema::Result::Personality;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components( "PK::Auto", "Core" );
__PACKAGE__->table("personality");
__PACKAGE__->add_columns( "user_id" => { data_type => 'integer' }, );
__PACKAGE__->set_primary_key("user_id");
__PACKAGE__->has_one( 'user', 'DBSchema::Result::User', {'foreign.id' => 'self.user_id'}, );

1;

