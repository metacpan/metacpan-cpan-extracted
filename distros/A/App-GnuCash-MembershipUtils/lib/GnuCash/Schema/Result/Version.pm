use utf8;
package GnuCash::Schema::Result::Version;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GnuCash::Schema::Result::Version

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

=head1 TABLE: C<versions>

=cut

__PACKAGE__->table("versions");

=head1 ACCESSORS

=head2 table_name

  data_type: 'text'
  is_nullable: 0
  size: 50

=head2 table_version

  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "table_name",
  { data_type => "text", is_nullable => 0, size => 50 },
  "table_version",
  { data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</table_name>

=back

=cut

__PACKAGE__->set_primary_key("table_name");


# Created by DBIx::Class::Schema::Loader v0.07052 @ 2024-02-18 13:56:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6Ajejp0B5re+xtReH2FL4w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
