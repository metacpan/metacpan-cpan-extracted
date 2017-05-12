use utf8;
package Sample::Schema::Result::Album;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Sample::Schema::Result::Album

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

=head1 TABLE: C<albums>

=cut

__PACKAGE__->table("albums");

=head1 ACCESSORS

=head2 album_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'text'
  is_nullable: 0

=head2 producer_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "album_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "text", is_nullable => 0 },
  "producer_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</album_id>

=back

=cut

__PACKAGE__->set_primary_key("album_id");

=head1 RELATIONS

=head2 people

Type: has_many

Related object: L<Sample::Schema::Result::Person>

=cut

__PACKAGE__->has_many(
  "people",
  "Sample::Schema::Result::Person",
  { "foreign.favorite_album_id" => "self.album_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 producer

Type: belongs_to

Related object: L<Sample::Schema::Result::Person>

=cut

__PACKAGE__->belongs_to(
  "producer",
  "Sample::Schema::Result::Person",
  { person_id => "producer_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-06-19 13:13:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9O7SUUMrEEkJeVFNNVlPyw


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
