package Business::Cart::Generic::Schema::Result::Zone;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Business::Cart::Generic::Schema::Result::Zone

=cut

__PACKAGE__->table("zones");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: 'zones_id_seq'

=head2 country_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 code

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
    sequence          => "zones_id_seq",
  },
  "country_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "code",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "upper_name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
);
__PACKAGE__->set_primary_key("id");

=head1 RELATIONS

=head2 street_addresses

Type: has_many

Related object: L<Business::Cart::Generic::Schema::Result::StreetAddress>

=cut

__PACKAGE__->has_many(
  "street_addresses",
  "Business::Cart::Generic::Schema::Result::StreetAddress",
  { "foreign.zone_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 tax_rates

Type: has_many

Related object: L<Business::Cart::Generic::Schema::Result::TaxRate>

=cut

__PACKAGE__->has_many(
  "tax_rates",
  "Business::Cart::Generic::Schema::Result::TaxRate",
  { "foreign.zone_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 country

Type: belongs_to

Related object: L<Business::Cart::Generic::Schema::Result::Country>

=cut

__PACKAGE__->belongs_to(
  "country",
  "Business::Cart::Generic::Schema::Result::Country",
  { id => "country_id" },
  { is_deferrable => 1, on_delete => "CASCADE", on_update => "CASCADE" },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-05-09 11:58:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:CJgZORYIi9r02Iothz/FfQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
