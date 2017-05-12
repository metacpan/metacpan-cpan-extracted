package Bio::Chado::Schema::Result::Pub::PubRelationship;
BEGIN {
  $Bio::Chado::Schema::Result::Pub::PubRelationship::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Pub::PubRelationship::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Pub::PubRelationship

=head1 DESCRIPTION

Handle relationships between
publications, e.g. when one publication makes others obsolete, when one
publication contains errata with respect to other publication(s), or
when one publication also appears in another pub.

=cut

__PACKAGE__->table("pub_relationship");

=head1 ACCESSORS

=head2 pub_relationship_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'pub_relationship_pub_relationship_id_seq'

=head2 subject_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 object_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "pub_relationship_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "pub_relationship_pub_relationship_id_seq",
  },
  "subject_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "object_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("pub_relationship_id");
__PACKAGE__->add_unique_constraint("pub_relationship_c1", ["subject_id", "object_id", "type_id"]);

=head1 RELATIONS

=head2 type

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Cv::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "type",
  "Bio::Chado::Schema::Result::Cv::Cvterm",
  { cvterm_id => "type_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 object

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Pub::Pub>

=cut

__PACKAGE__->belongs_to(
  "object",
  "Bio::Chado::Schema::Result::Pub::Pub",
  { pub_id => "object_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 subject

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Pub::Pub>

=cut

__PACKAGE__->belongs_to(
  "subject",
  "Bio::Chado::Schema::Result::Pub::Pub",
  { pub_id => "subject_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:NxczDRevB78l/UhBS2e47Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
