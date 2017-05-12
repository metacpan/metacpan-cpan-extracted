package Business::Cart::Generic::Schema::Result::Currency;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Business::Cart::Generic::Schema::Result::Currency

=cut

__PACKAGE__->table("currencies");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'currencies_id_seq'

=head2 code

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 decimal_places

  data_type: 'char'
  is_nullable: 0
  size: 1

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 symbol_left

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 symbol_right

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 upper_name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "currencies_id_seq",
  },
  "code",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "decimal_places",
  { data_type => "char", is_nullable => 0, size => 1 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "symbol_left",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "symbol_right",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "upper_name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 languages

Type: has_many

Related object: L<Business::Cart::Generic::Schema::Result::Language>

=cut

__PACKAGE__->has_many(
  "languages",
  "Business::Cart::Generic::Schema::Result::Language",
  { "foreign.currency_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 products

Type: has_many

Related object: L<Business::Cart::Generic::Schema::Result::Product>

=cut

__PACKAGE__->has_many(
  "products",
  "Business::Cart::Generic::Schema::Result::Product",
  { "foreign.currency_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-05-09 11:58:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:q96ZEL3fwEPy0hgKCQOn5w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
