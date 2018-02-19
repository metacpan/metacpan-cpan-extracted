use utf8;
package # hide from PAUSE
    CDTest::Schema::Result::Event;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CDTest::Schema::Result::Event

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<event>

=cut

__PACKAGE__->table("event");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 starts_at

  data_type: 'date'
  is_nullable: 0

=head2 created_on

  data_type: 'timestamp'
  is_nullable: 0

=head2 varchar_date

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 varchar_datetime

  data_type: 'varchar'
  is_nullable: 1
  size: 20

=head2 skip_inflation

  data_type: 'datetime'
  is_nullable: 1

=head2 ts_without_tz

  data_type: 'datetime'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "starts_at",
  { data_type => "date", is_nullable => 0 },
  "created_on",
  { data_type => "timestamp", is_nullable => 0 },
  "varchar_date",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "varchar_datetime",
  { data_type => "varchar", is_nullable => 1, size => 20 },
  "skip_inflation",
  { data_type => "datetime", is_nullable => 1 },
  "ts_without_tz",
  { data_type => "datetime", is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</id>

=back

=cut

__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-01-11 08:18:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:It578mTpvG1moqvLGi0I3Q


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
