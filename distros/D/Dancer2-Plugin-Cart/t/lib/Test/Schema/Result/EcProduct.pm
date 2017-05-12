use utf8;
package Test::Schema::Result::EcProduct;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Test::Schema::Result::EcProduct

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<ec_product>

=cut

__PACKAGE__->table("ec_product");

=head1 ACCESSORS

=head2 sku

  data_type: 'text'
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 price

  data_type: 'numeric'
  is_nullable: 0

=head2 description

  data_type: 'text'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "sku",
  { data_type => "text", is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "price",
  { data_type => "numeric", is_nullable => 0 },
  "description",
  { data_type => "text", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</sku>

=back

=cut

__PACKAGE__->set_primary_key("sku");


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-09-24 08:57:40
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CIbTXaioartGnaDBjJQZQA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
