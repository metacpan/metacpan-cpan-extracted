package Business::Cart::Generic::Schema::Result::Language;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Business::Cart::Generic::Schema::Result::Language

=cut

__PACKAGE__->table("languages");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'languages_id_seq'

=head2 currency_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 charset

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 code

  data_type: 'char'
  is_nullable: 0
  size: 5

=head2 date_format_long

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 date_format_short

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 locale

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 numeric_separator_decimal

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 numeric_separator_thousands

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 text_direction

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 time_format

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
    sequence          => "languages_id_seq",
  },
  "currency_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "charset",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "code",
  { data_type => "char", is_nullable => 0, size => 5 },
  "date_format_long",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "date_format_short",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "locale",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "numeric_separator_decimal",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "numeric_separator_thousands",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "text_direction",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "time_format",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "upper_name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 category_descriptions

Type: has_many

Related object: L<Business::Cart::Generic::Schema::Result::CategoryDescription>

=cut

__PACKAGE__->has_many(
  "category_descriptions",
  "Business::Cart::Generic::Schema::Result::CategoryDescription",
  { "foreign.language_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 currency

Type: belongs_to

Related object: L<Business::Cart::Generic::Schema::Result::Currency>

=cut

__PACKAGE__->belongs_to(
  "currency",
  "Business::Cart::Generic::Schema::Result::Currency",
  { id => "currency_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 manufacturers_infos

Type: has_many

Related object: L<Business::Cart::Generic::Schema::Result::ManufacturersInfo>

=cut

__PACKAGE__->has_many(
  "manufacturers_infos",
  "Business::Cart::Generic::Schema::Result::ManufacturersInfo",
  { "foreign.language_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 order_statuses

Type: has_many

Related object: L<Business::Cart::Generic::Schema::Result::OrderStatuse>

=cut

__PACKAGE__->has_many(
  "order_statuses",
  "Business::Cart::Generic::Schema::Result::OrderStatuse",
  { "foreign.language_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 product_descriptions

Type: has_many

Related object: L<Business::Cart::Generic::Schema::Result::ProductDescription>

=cut

__PACKAGE__->has_many(
  "product_descriptions",
  "Business::Cart::Generic::Schema::Result::ProductDescription",
  { "foreign.language_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 weight_classes

Type: has_many

Related object: L<Business::Cart::Generic::Schema::Result::WeightClass>

=cut

__PACKAGE__->has_many(
  "weight_classes",
  "Business::Cart::Generic::Schema::Result::WeightClass",
  { "foreign.language_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-05-09 11:58:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:uLAl2/ukzwuyxOgXDa1/LA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
