use utf8;
package GnuCash::Schema::Result::Slot;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GnuCash::Schema::Result::Slot

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

=head1 TABLE: C<slots>

=cut

__PACKAGE__->table("slots");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 obj_guid

  data_type: 'text'
  is_nullable: 0
  size: 32

=head2 name

  data_type: 'text'
  is_nullable: 0
  size: 4096

=head2 slot_type

  data_type: 'integer'
  is_nullable: 0

=head2 int64_val

  data_type: 'bigint'
  is_nullable: 1

=head2 string_val

  data_type: 'text'
  is_nullable: 1
  size: 4096

=head2 double_val

  data_type: 'float8'
  is_nullable: 1

=head2 timespec_val

  data_type: 'text'
  is_nullable: 1
  size: 19

=head2 guid_val

  data_type: 'text'
  is_nullable: 1
  size: 32

=head2 numeric_val_num

  data_type: 'bigint'
  is_nullable: 1

=head2 numeric_val_denom

  data_type: 'bigint'
  is_nullable: 1

=head2 gdate_val

  data_type: 'text'
  is_nullable: 1
  size: 8

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "obj_guid",
  { data_type => "text", is_nullable => 0, size => 32 },
  "name",
  { data_type => "text", is_nullable => 0, size => 4096 },
  "slot_type",
  { data_type => "integer", is_nullable => 0 },
  "int64_val",
  { data_type => "bigint", is_nullable => 1 },
  "string_val",
  { data_type => "text", is_nullable => 1, size => 4096 },
  "double_val",
  { data_type => "float8", is_nullable => 1 },
  "timespec_val",
  { data_type => "text", is_nullable => 1, size => 19 },
  "guid_val",
  { data_type => "text", is_nullable => 1, size => 32 },
  "numeric_val_num",
  { data_type => "bigint", is_nullable => 1 },
  "numeric_val_denom",
  { data_type => "bigint", is_nullable => 1 },
  "gdate_val",
  { data_type => "text", is_nullable => 1, size => 8 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07052 @ 2024-02-18 13:56:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:1b2fUrExcSpH6mn/TuJakA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
