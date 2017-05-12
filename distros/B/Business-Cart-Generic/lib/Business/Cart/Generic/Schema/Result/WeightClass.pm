package Business::Cart::Generic::Schema::Result::WeightClass;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Business::Cart::Generic::Schema::Result::WeightClass

=cut

__PACKAGE__->table("weight_classes");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'weight_classes_id_seq'

=head2 language_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 key

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 name

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
    sequence          => "weight_classes_id_seq",
  },
  "language_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "key",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "upper_name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 products

Type: has_many

Related object: L<Business::Cart::Generic::Schema::Result::Product>

=cut

__PACKAGE__->has_many(
  "products",
  "Business::Cart::Generic::Schema::Result::Product",
  { "foreign.weight_class_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 language

Type: belongs_to

Related object: L<Business::Cart::Generic::Schema::Result::Language>

=cut

__PACKAGE__->belongs_to(
  "language",
  "Business::Cart::Generic::Schema::Result::Language",
  { id => "language_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 weight_class_rules_to

Type: has_many

Related object: L<Business::Cart::Generic::Schema::Result::WeightClassRule>

=cut

__PACKAGE__->has_many(
  "weight_class_rules_to",
  "Business::Cart::Generic::Schema::Result::WeightClassRule",
  { "foreign.to_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 weight_class_rules_from

Type: has_many

Related object: L<Business::Cart::Generic::Schema::Result::WeightClassRule>

=cut

__PACKAGE__->has_many(
  "weight_class_rules_from",
  "Business::Cart::Generic::Schema::Result::WeightClassRule",
  { "foreign.from_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-05-09 11:58:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:aKCNJBAGNMBP6XiHJxo/Gg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
