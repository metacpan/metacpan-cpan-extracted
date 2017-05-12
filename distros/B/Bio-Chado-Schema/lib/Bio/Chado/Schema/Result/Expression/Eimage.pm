package Bio::Chado::Schema::Result::Expression::Eimage;
BEGIN {
  $Bio::Chado::Schema::Result::Expression::Eimage::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Expression::Eimage::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Expression::Eimage

=cut

__PACKAGE__->table("eimage");

=head1 ACCESSORS

=head2 eimage_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'eimage_eimage_id_seq'

=head2 eimage_data

  data_type: 'text'
  is_nullable: 1

We expect images in eimage_data (e.g. JPEGs) to be uuencoded.

=head2 eimage_type

  data_type: 'varchar'
  is_nullable: 0
  size: 255

Describes the type of data in eimage_data.

=head2 image_uri

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=cut

__PACKAGE__->add_columns(
  "eimage_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "eimage_eimage_id_seq",
  },
  "eimage_data",
  { data_type => "text", is_nullable => 1 },
  "eimage_type",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "image_uri",
  { data_type => "varchar", is_nullable => 1, size => 255 },
);
__PACKAGE__->set_primary_key("eimage_id");

=head1 RELATIONS

=head2 expression_images

Type: has_many

Related object: L<Bio::Chado::Schema::Result::Expression::ExpressionImage>

=cut

__PACKAGE__->has_many(
  "expression_images",
  "Bio::Chado::Schema::Result::Expression::ExpressionImage",
  { "foreign.eimage_id" => "self.eimage_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:S2G9Dp420ZT3+4953m8XMA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
