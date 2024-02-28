use utf8;
package GnuCash::Schema::Result::Taxtable;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GnuCash::Schema::Result::Taxtable

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

=head1 TABLE: C<taxtables>

=cut

__PACKAGE__->table("taxtables");

=head1 ACCESSORS

=head2 guid

  data_type: 'text'
  is_nullable: 0
  size: 32

=head2 name

  data_type: 'text'
  is_nullable: 0
  size: 50

=head2 refcount

  data_type: 'bigint'
  is_nullable: 0

=head2 invisible

  data_type: 'integer'
  is_nullable: 0

=head2 parent

  data_type: 'text'
  is_nullable: 1
  size: 32

=cut

__PACKAGE__->add_columns(
  "guid",
  { data_type => "text", is_nullable => 0, size => 32 },
  "name",
  { data_type => "text", is_nullable => 0, size => 50 },
  "refcount",
  { data_type => "bigint", is_nullable => 0 },
  "invisible",
  { data_type => "integer", is_nullable => 0 },
  "parent",
  { data_type => "text", is_nullable => 1, size => 32 },
);

=head1 PRIMARY KEY

=over 4

=item * L</guid>

=back

=cut

__PACKAGE__->set_primary_key("guid");


# Created by DBIx::Class::Schema::Loader v0.07052 @ 2024-02-18 13:56:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9cxNtfqvr1t6PXjScYCfjw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
