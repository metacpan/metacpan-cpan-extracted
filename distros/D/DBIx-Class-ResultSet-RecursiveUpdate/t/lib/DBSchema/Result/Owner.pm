package DBSchema::Result::Owner;

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

DBSchema::Result::Owner

=cut

__PACKAGE__->table("owner");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "text", default_value => "", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 podcasts

Type: has_many

Related object: L<DBSchema::Result::Podcast>

=cut

__PACKAGE__->has_many(
  "podcasts",
  "DBSchema::Result::Podcast",
  { "foreign.owner_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


1;
