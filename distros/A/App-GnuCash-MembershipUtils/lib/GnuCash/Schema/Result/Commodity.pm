use utf8;
package GnuCash::Schema::Result::Commodity;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GnuCash::Schema::Result::Commodity

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

=head1 TABLE: C<commodities>

=cut

__PACKAGE__->table("commodities");

=head1 ACCESSORS

=head2 guid

  data_type: 'text'
  is_nullable: 0
  size: 32

=head2 namespace

  data_type: 'text'
  is_nullable: 0
  size: 2048

=head2 mnemonic

  data_type: 'text'
  is_nullable: 0
  size: 2048

=head2 fullname

  data_type: 'text'
  is_nullable: 1
  size: 2048

=head2 cusip

  data_type: 'text'
  is_nullable: 1
  size: 2048

=head2 fraction

  data_type: 'integer'
  is_nullable: 0

=head2 quote_flag

  data_type: 'integer'
  is_nullable: 0

=head2 quote_source

  data_type: 'text'
  is_nullable: 1
  size: 2048

=head2 quote_tz

  data_type: 'text'
  is_nullable: 1
  size: 2048

=cut

__PACKAGE__->add_columns(
  "guid",
  { data_type => "text", is_nullable => 0, size => 32 },
  "namespace",
  { data_type => "text", is_nullable => 0, size => 2048 },
  "mnemonic",
  { data_type => "text", is_nullable => 0, size => 2048 },
  "fullname",
  { data_type => "text", is_nullable => 1, size => 2048 },
  "cusip",
  { data_type => "text", is_nullable => 1, size => 2048 },
  "fraction",
  { data_type => "integer", is_nullable => 0 },
  "quote_flag",
  { data_type => "integer", is_nullable => 0 },
  "quote_source",
  { data_type => "text", is_nullable => 1, size => 2048 },
  "quote_tz",
  { data_type => "text", is_nullable => 1, size => 2048 },
);

=head1 PRIMARY KEY

=over 4

=item * L</guid>

=back

=cut

__PACKAGE__->set_primary_key("guid");


# Created by DBIx::Class::Schema::Loader v0.07052 @ 2024-02-18 13:56:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:09kXSKKECH71eazMIb3Elw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
