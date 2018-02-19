use utf8;
package # hide from PAUSE
    CDTest::Schema::Result::Year2000CD;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

CDTest::Schema::Result::Year2000CD

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';
__PACKAGE__->table_class("DBIx::Class::ResultSource::View");

=head1 TABLE: C<year2000cds>

=cut

__PACKAGE__->table("year2000cds");

=head1 ACCESSORS

=head2 cdid

  data_type: 'integer'
  is_nullable: 1

=head2 artist

  data_type: 'integer'
  is_nullable: 1

=head2 title

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 year

  data_type: 'varchar'
  is_nullable: 1
  size: 100

=head2 genreid

  data_type: 'integer'
  is_nullable: 1

=head2 single_track

  data_type: 'integer'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "cdid",
  { data_type => "integer", is_nullable => 1 },
  "artist",
  { data_type => "integer", is_nullable => 1 },
  "title",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "year",
  { data_type => "varchar", is_nullable => 1, size => 100 },
  "genreid",
  { data_type => "integer", is_nullable => 1 },
  "single_track",
  { data_type => "integer", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07047 @ 2018-01-11 08:18:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:6KWu91X/lN6xcahIMcoUKw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
