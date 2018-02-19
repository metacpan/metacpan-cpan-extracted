use utf8;
package # hide from PAUSE
    CDTest::Schema::Result::Encoded;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CDTest::Schema::Result::Encoded

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<encoded>

=cut

__PACKAGE__->table("encoded");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 encoded

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "encoded",
  { data_type => "varchar", is_nullable => 1, size => 100 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-01-11 08:18:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:3fQUQcH1+sGX3q8n/DIngQ


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
