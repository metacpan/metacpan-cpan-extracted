use utf8;
package GnuCash::Schema::Result::Book;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

GnuCash::Schema::Result::Book

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

=head1 TABLE: C<books>

=cut

__PACKAGE__->table("books");

=head1 ACCESSORS

=head2 guid

  data_type: 'text'
  is_nullable: 0
  size: 32

=head2 root_account_guid

  data_type: 'text'
  is_nullable: 0
  size: 32

=head2 root_template_guid

  data_type: 'text'
  is_nullable: 0
  size: 32

=cut

__PACKAGE__->add_columns(
  "guid",
  { data_type => "text", is_nullable => 0, size => 32 },
  "root_account_guid",
  { data_type => "text", is_nullable => 0, size => 32 },
  "root_template_guid",
  { data_type => "text", is_nullable => 0, size => 32 },
);

=head1 PRIMARY KEY

=over 4

=item * L</guid>

=back

=cut

__PACKAGE__->set_primary_key("guid");


# Created by DBIx::Class::Schema::Loader v0.07052 @ 2024-02-18 13:56:36
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:VextuO733SUtF3Xtj9Zv0Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
