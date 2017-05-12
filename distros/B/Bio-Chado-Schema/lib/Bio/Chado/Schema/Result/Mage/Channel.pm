package Bio::Chado::Schema::Result::Mage::Channel;
BEGIN {
  $Bio::Chado::Schema::Result::Mage::Channel::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Mage::Channel::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Mage::Channel

=head1 DESCRIPTION

Different array platforms can record signals from one or more channels (cDNA arrays typically use two CCD, but Affymetrix uses only one).

=cut

__PACKAGE__->table("channel");

=head1 ACCESSORS

=head2 channel_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'channel_channel_id_seq'

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 definition

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "channel_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "channel_channel_id_seq",
  },
  "name",
  { data_type => "text", is_nullable => 0 },
  "definition",
  { data_type => "text", is_nullable => 0 },
);
__PACKAGE__->set_primary_key("channel_id");
__PACKAGE__->add_unique_constraint("channel_c1", ["name"]);

=head1 RELATIONS

=head2 acquisitions

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::Acquisition>

=cut

__PACKAGE__->has_many(
  "acquisitions",
  "Bio::Chado::Schema::Result::Mage::Acquisition",
  { "foreign.channel_id" => "self.channel_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 assay_biomaterials

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Mage::AssayBiomaterial>

=cut

__PACKAGE__->has_many(
  "assay_biomaterials",
  "Bio::Chado::Schema::Result::Mage::AssayBiomaterial",
  { "foreign.channel_id" => "self.channel_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:0kdfxPCxnjzP0qF2xiblGA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
