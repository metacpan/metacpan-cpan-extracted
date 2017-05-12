package Schema_ad_lookups_inside::Result::RoleType;

use strict;
use warnings;
use base qw/DBIx::Class::Core/;



__PACKAGE__->table("roletype");

__PACKAGE__->add_columns(

	"role_id", { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
	"name",    { data_type => "varchar2", is_nullable => 0, size => 45 } 
);

__PACKAGE__->set_primary_key("role_id");

__PACKAGE__->has_many('actorroles', 'Schema_ad_lookups_inside::Result::ActorRole', { 'foreign.role_id' => 'self.role_id' } );
__PACKAGE__->many_to_many('actors', 'actorroles', 'actor');

1;
