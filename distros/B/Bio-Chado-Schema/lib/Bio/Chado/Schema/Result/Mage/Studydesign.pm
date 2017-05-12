package Bio::Chado::Schema::Result::Mage::Studydesign;
BEGIN {
  $Bio::Chado::Schema::Result::Mage::Studydesign::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Mage::Studydesign::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Mage::Studydesign

=cut

__PACKAGE__->table("studydesign");

=head1 ACCESSORS

=head2 studydesign_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'studydesign_studydesign_id_seq'

=head2 study_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 description

  data_type: 'text'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "studydesign_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "studydesign_studydesign_id_seq",
  },
  "study_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "description",
  { data_type => "text", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("studydesign_id");

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

=head2 studydesignprops

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Studydesignprop>

=cut

__PACKAGE__->has_many(
  "studydesignprops",
  "Bio::Chado::Schema::Result::Mage::Studydesignprop",
  { "foreign.studydesign_id" => "self.studydesign_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 studyfactors

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Studyfactor>

=cut

__PACKAGE__->has_many(
  "studyfactors",
  "Bio::Chado::Schema::Result::Mage::Studyfactor",
  { "foreign.studydesign_id" => "self.studydesign_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:vD7ojU0ZWCDAyP+EZDi8Mw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
