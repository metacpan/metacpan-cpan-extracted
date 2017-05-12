package Bio::Chado::Schema::Result::Mage::AssayProject;
BEGIN {
  $Bio::Chado::Schema::Result::Mage::AssayProject::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Mage::AssayProject::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Mage::AssayProject - Link assays to projects.

=cut

__PACKAGE__->table("assay_project");

=head1 ACCESSORS

=head2 assay_project_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'assay_project_assay_project_id_seq'

=head2 assay_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 project_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "assay_project_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "assay_project_assay_project_id_seq",
  },
  "assay_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "project_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("assay_project_id");
__PACKAGE__->add_unique_constraint("assay_project_c1", ["assay_id", "project_id"]);

=head1 RELATIONS

=head2 project

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Project::Project>

=cut

__PACKAGE__->belongs_to(
  "project",
  "Bio::Chado::Schema::Result::Project::Project",
  { project_id => "project_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 assay

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Mage::Assay>

=cut

__PACKAGE__->belongs_to(
  "assay",
  "Bio::Chado::Schema::Result::Mage::Assay",
  { assay_id => "assay_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:biZL5hZlp1mXOWiz86g1Uw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
