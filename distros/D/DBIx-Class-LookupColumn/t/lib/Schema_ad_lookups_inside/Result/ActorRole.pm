package Schema_ad_lookups_inside::Result::ActorRole;

use strict;
use warnings;
use base qw/DBIx::Class::Core/;


__PACKAGE__->table("actorrole");

__PACKAGE__->add_columns(
      
		"role_id",	{ data_type => "integer", is_foreign_key=> 1, is_nullable => 0 },
		"actor_id",	{ data_type => "integer", is_foreign_key=> 1, is_nullable => 0 },    
);

__PACKAGE__->set_primary_key("actor_id", "role_id");


__PACKAGE__->belongs_to('roletype', 'Schema_ad_lookups_inside::Result::RoleType', { 'foreign.role_id' =>  'self.role_id' } );
__PACKAGE__->belongs_to('actor',  'Schema_ad_lookups_inside::Result::Actor', { 'foreign.actor_id' => 'self.actor_id'});


1;