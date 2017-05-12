package Bio::Chado::Schema::Result::Mage::Studyfactorvalue;
BEGIN {
  $Bio::Chado::Schema::Result::Mage::Studyfactorvalue::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Mage::Studyfactorvalue::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Mage::Studyfactorvalue

=cut

__PACKAGE__->table("studyfactorvalue");

=head1 ACCESSORS

=head2 studyfactorvalue_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'studyfactorvalue_studyfactorvalue_id_seq'

=head2 studyfactor_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 assay_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 factorvalue

  data_type: 'text'
  is_nullable: 1

=head2 name

  data_type: 'text'
  is_nullable: 1

=head2 rank

  data_type: 'integer'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "studyfactorvalue_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "studyfactorvalue_studyfactorvalue_id_seq",
  },
  "studyfactor_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "assay_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "factorvalue",
  { data_type => "text", is_nullable => 1 },
  "name",
  { data_type => "text", is_nullable => 1 },
  "rank",
  { data_type => "integer", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("studyfactorvalue_id");

=head1 RELATIONS

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

=head2 studyfactor

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Mage::Studyfactor>

=cut

__PACKAGE__->belongs_to(
  "studyfactor",
  "Bio::Chado::Schema::Result::Mage::Studyfactor",
  { studyfactor_id => "studyfactor_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:SEoB74WoJbcRCF6oQlQWYA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
