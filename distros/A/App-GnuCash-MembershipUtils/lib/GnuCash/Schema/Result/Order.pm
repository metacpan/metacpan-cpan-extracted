use utf8;
package GnuCash::Schema::Result::Order;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GnuCash::Schema::Result::Order

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

=head1 TABLE: C<orders>

=cut

__PACKAGE__->table("orders");

=head1 ACCESSORS

=head2 guid

  data_type: 'text'
  is_nullable: 0
  size: 32

=head2 id

  data_type: 'text'
  is_nullable: 0
  size: 2048

=head2 notes

  data_type: 'text'
  is_nullable: 0
  size: 2048

=head2 reference

  data_type: 'text'
  is_nullable: 0
  size: 2048

=head2 active

  data_type: 'integer'
  is_nullable: 0

=head2 date_opened

  data_type: 'text'
  is_nullable: 0
  size: 19

=head2 date_closed

  data_type: 'text'
  is_nullable: 0
  size: 19

=head2 owner_type

  data_type: 'integer'
  is_nullable: 0

=head2 owner_guid

  data_type: 'text'
  is_nullable: 0
  size: 32

=cut

__PACKAGE__->add_columns(
  "guid",
  { data_type => "text", is_nullable => 0, size => 32 },
  "id",
  { data_type => "text", is_nullable => 0, size => 2048 },
  "notes",
  { data_type => "text", is_nullable => 0, size => 2048 },
  "reference",
  { data_type => "text", is_nullable => 0, size => 2048 },
  "active",
  { data_type => "integer", is_nullable => 0 },
  "date_opened",
  { data_type => "text", is_nullable => 0, size => 19 },
  "date_closed",
  { data_type => "text", is_nullable => 0, size => 19 },
  "owner_type",
  { data_type => "integer", is_nullable => 0 },
  "owner_guid",
  { data_type => "text", is_nullable => 0, size => 32 },
);

=head1 PRIMARY KEY

=over 4

=item * L</guid>

=back

=cut

__PACKAGE__->set_primary_key("guid");


# Created by DBIx::Class::Schema::Loader v0.07052 @ 2024-02-18 13:56:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:eWo5BOGsxq5D8XXCsiWCyg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
