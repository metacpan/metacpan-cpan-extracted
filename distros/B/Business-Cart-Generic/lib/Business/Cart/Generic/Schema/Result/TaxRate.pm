package Business::Cart::Generic::Schema::Result::TaxRate;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Business::Cart::Generic::Schema::Result::TaxRate

=cut

__PACKAGE__->table("tax_rates");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'tax_rates_id_seq'

=head2 tax_class_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 zone_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 date_added

  data_type: 'timestamp'
  is_nullable: 0

=head2 date_modified

  data_type: 'timestamp'
  is_nullable: 0

=head2 description

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 priority

  data_type: 'integer'
  default_value: 1
  is_nullable: 1

=head2 rate

  data_type: 'numeric'
  is_nullable: 0
  size: [7,4]

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
    sequence          => "tax_rates_id_seq",
  },
  "tax_class_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "zone_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "date_added",
  { data_type => "timestamp", is_nullable => 0 },
  "date_modified",
  { data_type => "timestamp", is_nullable => 0 },
  "description",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "priority",
  { data_type => "integer", default_value => 1, is_nullable => 1 },
  "rate",
  { data_type => "numeric", is_nullable => 0, size => [7, 4] },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "upper_name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 zone

Type: belongs_to

Related object: L<Business::Cart::Generic::Schema::Result::Zone>

=cut

__PACKAGE__->belongs_to(
  "zone",
  "Business::Cart::Generic::Schema::Result::Zone",
  { id => "zone_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);

=head2 tax_class

Type: belongs_to

Related object: L<Business::Cart::Generic::Schema::Result::TaxClass>

=cut

__PACKAGE__->belongs_to(
  "tax_class",
  "Business::Cart::Generic::Schema::Result::TaxClass",
  { id => "tax_class_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-05-09 11:58:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fbeVa8jcwCNsuVH+29sCAw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
