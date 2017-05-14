use utf8;
package Test::Schema::Result::Sales;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Test::Schema::Result::Sales

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<sales>

=cut

__PACKAGE__->table("sales");

=head1 ACCESSORS

=head2 fruit

  data_type: 'varchar'
  is_nullable: 1
  size: 16

=head2 country

  data_type: 'varchar'
  is_nullable: 1
  size: 32

=head2 channel

  data_type: 'varchar'
  is_nullable: 1
  size: 16

=head2 units

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "fruit",
  { data_type => "varchar", is_nullable => 1, size => 16 },
  "country",
  { data_type => "varchar", is_nullable => 1, size => 32 },
  "channel",
  { data_type => "varchar", is_nullable => 1, size => 16 },
  "units",
  { data_type => "integer", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2016-12-17 10:11:48
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rGHaQPW2QmpNwEwtQ0Qx/w


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
