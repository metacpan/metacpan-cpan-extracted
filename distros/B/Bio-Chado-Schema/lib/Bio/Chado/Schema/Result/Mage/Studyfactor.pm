package Bio::Chado::Schema::Result::Mage::Studyfactor;
BEGIN {
  $Bio::Chado::Schema::Result::Mage::Studyfactor::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Mage::Studyfactor::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Mage::Studyfactor

=cut

__PACKAGE__->table("studyfactor");

=head1 ACCESSORS

=head2 studyfactor_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'studyfactor_studyfactor_id_seq'

=head2 studydesign_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 type_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 description

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "studyfactor_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "studyfactor_studyfactor_id_seq",
  },
  "studydesign_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "type_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "description",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("studyfactor_id");

=head1 RELATIONS

=head2 studydesign

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Mage::Studydesign>

=cut

__PACKAGE__->belongs_to(
  "studydesign",
  "Bio::Chado::Schema::Result::Mage::Studydesign",
  { studydesign_id => "studydesign_id" },
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
    join_type      => "LEFT",
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 studyfactorvalues

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Studyfactorvalue>

=cut

__PACKAGE__->has_many(
  "studyfactorvalues",
  "Bio::Chado::Schema::Result::Mage::Studyfactorvalue",
  { "foreign.studyfactor_id" => "self.studyfactor_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:a1EHaIeoPwwbkSk+7s1Yaw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
