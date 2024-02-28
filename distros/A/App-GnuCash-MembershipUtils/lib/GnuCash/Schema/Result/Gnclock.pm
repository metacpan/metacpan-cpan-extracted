use utf8;
package GnuCash::Schema::Result::Gnclock;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GnuCash::Schema::Result::Gnclock

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

=head1 TABLE: C<gnclock>

=cut

__PACKAGE__->table("gnclock");

=head1 ACCESSORS

=head2 hostname

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 pid

  data_type: 'int'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "hostname",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "pid",
  { data_type => "int", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07052 @ 2024-02-18 13:56:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5ZYUWa+FxK14ByCAC6b42g


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
