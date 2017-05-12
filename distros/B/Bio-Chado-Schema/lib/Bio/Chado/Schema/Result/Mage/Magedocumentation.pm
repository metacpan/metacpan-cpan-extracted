package Bio::Chado::Schema::Result::Mage::Magedocumentation;
BEGIN {
  $Bio::Chado::Schema::Result::Mage::Magedocumentation::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Mage::Magedocumentation::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Mage::Magedocumentation

=cut

__PACKAGE__->table("magedocumentation");

=head1 ACCESSORS

=head2 magedocumentation_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'magedocumentation_magedocumentation_id_seq'

=head2 mageml_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 tableinfo_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 row_id

  data_type: 'integer'
  is_nullable: 0

=head2 mageidentifier

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "magedocumentation_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "magedocumentation_magedocumentation_id_seq",
  },
  "mageml_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "tableinfo_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "row_id",
  { data_type => "integer", is_nullable => 0 },
  "mageidentifier",
  { data_type => "text", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("magedocumentation_id");

=head1 RELATIONS

=head2 tableinfo

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::General::Tableinfo>

=cut

__PACKAGE__->belongs_to(
  "tableinfo",
  "Bio::Chado::Schema::Result::General::Tableinfo",
  { tableinfo_id => "tableinfo_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 mageml

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Mage::Mageml>

=cut

__PACKAGE__->belongs_to(
  "mageml",
  "Bio::Chado::Schema::Result::Mage::Mageml",
  { mageml_id => "mageml_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:59
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:r/wg2bcJGssYhjqBBPBmAg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
