use utf8;
package Sample::Schema::Result::Customer;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Sample::Schema::Result::Customer

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 COMPONENTS LOADED

=over 4

=item * L<DBIx::Class::InflateColumn::DateTime>

=back

=cut

__PACKAGE__->load_components("InflateColumn::DateTime");

=head1 TABLE: C<customers>

=cut

__PACKAGE__->table("customers");

=head1 ACCESSORS

=head2 customer_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 person_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 0

=head2 first_purchase

  data_type: 'datetime'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "customer_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "person_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 0 },
  "first_purchase",
  { data_type => "datetime", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</customer_id>

=back

=cut

__PACKAGE__->set_primary_key("customer_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<person_id_unique>

=over 4

=item * L</person_id>

=back

=cut

__PACKAGE__->add_unique_constraint("person_id_unique", ["person_id"]);

=head1 RELATIONS

=head2 orders

Type: has_many

Related object: L<Sample::Schema::Result::Order>

=cut

__PACKAGE__->has_many(
  "orders",
  "Sample::Schema::Result::Order",
  { "foreign.customer_id" => "self.customer_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 person

Type: belongs_to

Related object: L<Sample::Schema::Result::Person>

=cut

__PACKAGE__->belongs_to(
  "person",
  "Sample::Schema::Result::Person",
  { person_id => "person_id" },
  { is_deferrable => 0, on_delete => "NO ACTION", on_update => "NO ACTION" },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-02-13 13:30:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:wNacrNooUc4dy8uzG9LjcQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
