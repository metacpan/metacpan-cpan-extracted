use utf8;
package Test::Schema::Result::EcCartProduct;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Test::Schema::Result::EcCartProduct

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<ec_cart_product>

=cut

__PACKAGE__->table("ec_cart_product");

=head1 ACCESSORS

=head2 cart_id

  data_type: 'integer'
  is_nullable: 0

=head2 sku

  data_type: 'text'
  is_nullable: 0

=head2 price

  data_type: 'numeric'
  is_nullable: 0

=head2 quantity

  data_type: 'integer'
  is_nullable: 0

=cut

=head2 place 

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "cart_id",
  { data_type => "integer", is_nullable => 0 },
  "sku",
  { data_type => "text", is_nullable => 0 },
  "price",
  { data_type => "numeric", is_nullable => 0 },
  "quantity",
  { data_type => "integer", is_nullable => 0 },
  "place",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</cart_id>

=item * L</sku>

=back

=cut

__PACKAGE__->set_primary_key("cart_id", "sku");


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-09-24 09:13:58
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:PZTJgjBGjNjgDP7mp7oMcw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
