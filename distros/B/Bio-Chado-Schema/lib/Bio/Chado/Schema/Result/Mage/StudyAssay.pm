package Bio::Chado::Schema::Result::Mage::StudyAssay;
BEGIN {
  $Bio::Chado::Schema::Result::Mage::StudyAssay::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Mage::StudyAssay::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Mage::StudyAssay

=cut

__PACKAGE__->table("study_assay");

=head1 ACCESSORS

=head2 study_assay_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'study_assay_study_assay_id_seq'

=head2 study_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 assay_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "study_assay_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "study_assay_study_assay_id_seq",
  },
  "study_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "assay_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("study_assay_id");
__PACKAGE__->add_unique_constraint("study_assay_c1", ["study_id", "assay_id"]);

=head1 RELATIONS

=head2 study

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Mage::Study>

=cut

__PACKAGE__->belongs_to(
  "study",
  "Bio::Chado::Schema::Result::Mage::Study",
  { study_id => "study_id" },
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


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:+vL3u4ik5HFr9TRrzQ14XQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
