package Bio::Chado::Schema::Result::Contact::ContactRelationship;
BEGIN {
  $Bio::Chado::Schema::Result::Contact::ContactRelationship::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Contact::ContactRelationship::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Contact::ContactRelationship - Model relationships between contacts

=cut

__PACKAGE__->table("contact_relationship");

=head1 ACCESSORS

=head2 contact_relationship_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'contact_relationship_contact_relationship_id_seq'

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

Relationship type between subject and object. This is a cvterm, typically from the OBO relationship ontology, although other relationship types are allowed.

=head2 subject_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

The subject of the subj-predicate-obj sentence. In a DAG, this corresponds to the child node.

=head2 object_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

The object of the subj-predicate-obj sentence. In a DAG, this corresponds to the parent node.

=cut

__PACKAGE__->add_columns(
  "contact_relationship_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "contact_relationship_contact_relationship_id_seq",
  },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "subject_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "object_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("contact_relationship_id");
__PACKAGE__->add_unique_constraint(
  "contact_relationship_c1",
  ["subject_id", "object_id", "type_id"],
);

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

Related object: L<Bio::Chado::Schema::Result::Contact::Contact>

=cut

__PACKAGE__->belongs_to(
  "object",
  "Bio::Chado::Schema::Result::Contact::Contact",
  { contact_id => "object_id" },
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

Related object: L<Bio::Chado::Schema::Result::Contact::Contact>

=cut

__PACKAGE__->belongs_to(
  "subject",
  "Bio::Chado::Schema::Result::Contact::Contact",
  { contact_id => "subject_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:Iy0whmkxLpn38W7f4lZ8cw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
