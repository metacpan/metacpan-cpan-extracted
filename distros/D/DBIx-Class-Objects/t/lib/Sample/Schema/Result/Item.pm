use utf8;
package Sample::Schema::Result::Item;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Sample::Schema::Result::Item

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

=head1 TABLE: C<items>

=cut

__PACKAGE__->table("items");

=head1 ACCESSORS

=head2 item_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 price

  data_type: 'real'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "item_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "price",
  { data_type => "real", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</item_id>

=back

=cut

__PACKAGE__->set_primary_key("item_id");

=head1 RELATIONS

=head2 order_items

Type: has_many

Related object: L<Sample::Schema::Result::OrderItem>

=cut

__PACKAGE__->has_many(
  "order_items",
  "Sample::Schema::Result::OrderItem",
  { "foreign.item_id" => "self.item_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-02-13 13:30:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:jDqv+XEj9TGXg7DN7B4vmw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
