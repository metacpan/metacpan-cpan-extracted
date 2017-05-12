package Bio::Chado::Schema::Result::Expression::ExpressionImage;
BEGIN {
  $Bio::Chado::Schema::Result::Expression::ExpressionImage::AUTHORITY = 'cpan:RBUELS';
}
{
  $Bio::Chado::Schema::Result::Expression::ExpressionImage::VERSION = '0.20000';
}

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bio::Chado::Schema::Result::Expression::ExpressionImage

=cut

__PACKAGE__->table("expression_image");

=head1 ACCESSORS

=head2 expression_image_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'expression_image_expression_image_id_seq'

=head2 expression_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 eimage_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "expression_image_id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "expression_image_expression_image_id_seq",
  },
  "expression_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "eimage_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("expression_image_id");
__PACKAGE__->add_unique_constraint("expression_image_c1", ["expression_id", "eimage_id"]);

=head1 RELATIONS

=head2 eimage

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Expression::Eimage>

=cut

__PACKAGE__->belongs_to(
  "eimage",
  "Bio::Chado::Schema::Result::Expression::Eimage",
  { eimage_id => "eimage_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);

=head2 expression

Type: belongs_to

Related object: L<Bio::Chado::Schema::Result::Expression::Expression>

=cut

__PACKAGE__->belongs_to(
  "expression",
  "Bio::Chado::Schema::Result::Expression::Expression",
  { expression_id => "expression_id" },
  {
    cascade_copy   => 0,
    cascade_delete => 0,
    is_deferrable  => 1,
    on_delete      => "CASCADE",
    on_update      => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-03-16 23:09:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:c43DnCw/XkaJ5lZJcWxDDw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
