use utf8;
package GnuCash::Schema::Result::Transaction;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GnuCash::Schema::Result::Transaction

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

=head1 TABLE: C<transactions>

=cut

__PACKAGE__->table("transactions");

=head1 ACCESSORS

=head2 guid

  data_type: 'text'
  is_nullable: 0
  size: 32

=head2 currency_guid

  data_type: 'text'
  is_nullable: 0
  size: 32

=head2 num

  data_type: 'text'
  is_nullable: 0
  size: 2048

=head2 post_date

  data_type: 'text'
  is_nullable: 1
  size: 19

=head2 enter_date

  data_type: 'text'
  is_nullable: 1
  size: 19

=head2 description

  data_type: 'text'
  is_nullable: 1
  size: 2048

=cut

__PACKAGE__->add_columns(
  "guid",
  { data_type => "text", is_nullable => 0, size => 32 },
  "currency_guid",
  { data_type => "text", is_nullable => 0, size => 32 },
  "num",
  { data_type => "text", is_nullable => 0, size => 2048 },
  "post_date",
  { data_type => "text", is_nullable => 1, size => 19 },
  "enter_date",
  { data_type => "text", is_nullable => 1, size => 19 },
  "description",
  { data_type => "text", is_nullable => 1, size => 2048 },
);

=head1 PRIMARY KEY

=over 4

=item * L</guid>

=back

=cut

__PACKAGE__->set_primary_key("guid");


# Created by DBIx::Class::Schema::Loader v0.07052 @ 2024-02-18 13:56:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:RsDOUvzBGSDSzYrqpoJtdA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
