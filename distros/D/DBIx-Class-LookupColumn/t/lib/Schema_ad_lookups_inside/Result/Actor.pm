package Schema_ad_lookups_inside::Result::Actor;

use strict;
use warnings;
use base qw/DBIx::Class::Core/;


__PACKAGE__->table("actor");

__PACKAGE__->add_columns(
      "actor_id",	{ data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
      "first_name",	{ data_type => "varchar2", is_nullable => 0, size => 45 },
      "last_name",	{ data_type => "varchar2", is_nullable => 0, size => 45 } 
);

__PACKAGE__->set_primary_key("actor_id");

__PACKAGE__->has_many('actorroles', 'Schema_ad_lookups_inside::Result::ActorRole', { 'foreign.actor_id' => 'self.actor_id' } );
__PACKAGE__->many_to_many('roletypes',  'actorroles', 'roletype');

sub role_names {
	my $self = shift;
	return map { $_->role() } $self->actorroles;
};

sub has_role {
	my ( $self, $role_name ) = @_;
	my $found = grep { $_->is_role( $role_name ) }  $self->actorroles;
	return $found;
}

1;