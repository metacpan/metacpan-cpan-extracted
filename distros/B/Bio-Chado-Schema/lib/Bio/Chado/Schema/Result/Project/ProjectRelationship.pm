package Bio::Chado::Schema::Result::Project::ProjectRelationship;
BEGIN {
  $Bio::Chado::Schema::Result::Project::ProjectRelationship::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Project::ProjectRelationship::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Project::ProjectRelationship

=head1 DESCRIPTION

Linking table for relating projects to each other.  For example, a
given project could be composed of several smaller subprojects

=cut

__PACKAGE__->table("project_relationship");

=head1 ACCESSORS

=head2 project_relationship_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'project_relationship_project_relationship_id_seq'

=head2 subject_project_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 object_project_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

The cvterm type of the relationship being stated, such as "part of".

=cut

__PACKAGE__->add_columns(
  "project_relationship_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "project_relationship_project_relationship_id_seq",
  },
  "subject_project_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "object_project_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("project_relationship_id");
__PACKAGE__->add_unique_constraint(
  "project_relationship_c1",
  ["subject_project_id", "object_project_id", "type_id"],
);

=head1 RELATIONS

=head2 subject_project

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Project::Project>

=cut

__PACKAGE__->belongs_to(
  "subject_project",
  "Bio::Chado::Schema::Result::Project::Project",
  { project_id => "subject_project_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

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

=head2 object_project

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Project::Project>

=cut

__PACKAGE__->belongs_to(
  "object_project",
  "Bio::Chado::Schema::Result::Project::Project",
  { project_id => "object_project_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2012-07-06 11:44:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:srUsY6kGrK8qbGBQccUr0Q


# You can replace this text with custom content, and it will be preserved on regeneration
1;
