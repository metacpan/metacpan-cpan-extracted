use utf8;
package # hide from PAUSE
    CDTest::Schema::Result::Collection;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CDTest::Schema::Result::Collection

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<collection>

=cut

__PACKAGE__->table("collection");

=head1 ACCESSORS

=head2 collectionid

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=cut

__PACKAGE__->add_columns(
  "collectionid",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 100 },
);

=head1 PRIMARY KEY

=over 4

=item * L</collectionid>

=back

=cut

__PACKAGE__->set_primary_key("collectionid");


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-01-11 08:18:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:7ONjmVcF9y3b5/lNLNCHIg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
