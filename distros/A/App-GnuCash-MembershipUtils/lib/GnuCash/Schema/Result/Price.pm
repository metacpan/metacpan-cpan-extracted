use utf8;
package GnuCash::Schema::Result::Price;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GnuCash::Schema::Result::Price

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

=head1 TABLE: C<prices>

=cut

__PACKAGE__->table("prices");

=head1 ACCESSORS

=head2 guid

  data_type: 'text'
  is_nullable: 0
  size: 32

=head2 commodity_guid

  data_type: 'text'
  is_nullable: 0
  size: 32

=head2 currency_guid

  data_type: 'text'
  is_nullable: 0
  size: 32

=head2 date

  data_type: 'text'
  is_nullable: 0
  size: 19

=head2 source

  data_type: 'text'
  is_nullable: 1
  size: 2048

=head2 type

  data_type: 'text'
  is_nullable: 1
  size: 2048

=head2 value_num

  data_type: 'bigint'
  is_nullable: 0

=head2 value_denom

  data_type: 'bigint'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "guid",
  { data_type => "text", is_nullable => 0, size => 32 },
  "commodity_guid",
  { data_type => "text", is_nullable => 0, size => 32 },
  "currency_guid",
  { data_type => "text", is_nullable => 0, size => 32 },
  "date",
  { data_type => "text", is_nullable => 0, size => 19 },
  "source",
  { data_type => "text", is_nullable => 1, size => 2048 },
  "type",
  { data_type => "text", is_nullable => 1, size => 2048 },
  "value_num",
  { data_type => "bigint", is_nullable => 0 },
  "value_denom",
  { data_type => "bigint", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</guid>

=back

=cut

__PACKAGE__->set_primary_key("guid");


# Created by DBIx::Class::Schema::Loader v0.07052 @ 2024-02-18 13:56:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:2fOcnaxcwUJ1dhL1pNW24g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
