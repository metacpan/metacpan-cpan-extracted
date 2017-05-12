package DBSchema::Result::Podcast;

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

testDB::Schema::Result::Dvd

=cut

__PACKAGE__->table("podcast");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 title

  data_type: 'text'
  default_value: (empty string)
  is_nullable: 0

=head2 owner_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "title",
  { data_type => "text", default_value => "", is_nullable => 0 },
  "owner_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 owner

Type: belongs_to

Related object: L<testDB::Schema::Result::Owner>

=cut

__PACKAGE__->belongs_to(
  "owner",
  "DBSchema::Result::Owner",
  { id => "owner_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);

1;
