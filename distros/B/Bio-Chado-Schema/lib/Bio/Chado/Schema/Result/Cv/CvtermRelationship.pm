package Bio::Chado::Schema::Result::Cv::CvtermRelationship;
BEGIN {
  $Bio::Chado::Schema::Result::Cv::CvtermRelationship::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Cv::CvtermRelationship::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Cv::CvtermRelationship

=head1 DESCRIPTION

A relationship linking two
cvterms. Each cvterm_relationship constitutes an edge in the graph
defined by the collection of cvterms and cvterm_relationships. The
meaning of the cvterm_relationship depends on the definition of the
cvterm R refered to by type_id. However, in general the definitions
are such that the statement "all SUBJs REL some OBJ" is true. The
cvterm_relationship statement is about the subject, not the
object. For example "insect wing part_of thorax".

=cut

__PACKAGE__->table("cvterm_relationship");

=head1 ACCESSORS

=head2 cvterm_relationship_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'cvterm_relationship_cvterm_relationship_id_seq'

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

The nature of the
relationship between subject and object. Note that relations are also
housed in the cvterm table, typically from the OBO relationship
ontology, although other relationship types are allowed.

=head2 subject_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

The subject of
the subj-predicate-obj sentence. The cvterm_relationship is about the
subject. In a graph, this typically corresponds to the child node.

=head2 object_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

The object of the
subj-predicate-obj sentence. The cvterm_relationship refers to the
object. In a graph, this typically corresponds to the parent node.

=cut

__PACKAGE__->add_columns(
  "cvterm_relationship_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "cvterm_relationship_cvterm_relationship_id_seq",
  },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "subject_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "object_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("cvterm_relationship_id");
__PACKAGE__->add_unique_constraint(
  "cvterm_relationship_c1",
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

Related object: L<Bio::Chado::Schema::Result::Cv::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "object",
  "Bio::Chado::Schema::Result::Cv::Cvterm",
  { cvterm_id => "object_id" },
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

Related object: L<Bio::Chado::Schema::Result::Cv::Cvterm>

=cut

__PACKAGE__->belongs_to(
  "subject",
  "Bio::Chado::Schema::Result::Cv::Cvterm",
  { cvterm_id => "subject_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:lcPHP3VbVNwBdAGgnG+7hg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
