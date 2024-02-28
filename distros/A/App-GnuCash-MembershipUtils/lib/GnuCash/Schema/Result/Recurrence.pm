use utf8;
package GnuCash::Schema::Result::Recurrence;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GnuCash::Schema::Result::Recurrence

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

=head1 TABLE: C<recurrences>

=cut

__PACKAGE__->table("recurrences");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 obj_guid

  data_type: 'text'
  is_nullable: 0
  size: 32

=head2 recurrence_mult

  data_type: 'integer'
  is_nullable: 0

=head2 recurrence_period_type

  data_type: 'text'
  is_nullable: 0
  size: 2048

=head2 recurrence_period_start

  data_type: 'text'
  is_nullable: 0
  size: 8

=head2 recurrence_weekend_adjust

  data_type: 'text'
  is_nullable: 0
  size: 2048

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "obj_guid",
  { data_type => "text", is_nullable => 0, size => 32 },
  "recurrence_mult",
  { data_type => "integer", is_nullable => 0 },
  "recurrence_period_type",
  { data_type => "text", is_nullable => 0, size => 2048 },
  "recurrence_period_start",
  { data_type => "text", is_nullable => 0, size => 8 },
  "recurrence_weekend_adjust",
  { data_type => "text", is_nullable => 0, size => 2048 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07052 @ 2024-02-18 13:56:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3rq4I87Ab0tZw7KgCsmJSA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
