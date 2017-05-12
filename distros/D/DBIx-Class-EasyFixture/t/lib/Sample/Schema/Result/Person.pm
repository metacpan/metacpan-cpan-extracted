use utf8;
package Sample::Schema::Result::Person;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Sample::Schema::Result::Person

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

=head1 TABLE: C<people>

=cut

__PACKAGE__->table("people");

=head1 ACCESSORS

=head2 person_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 255

=head2 email

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 birthday

  data_type: 'datetime'
  is_nullable: 0

=head2 favorite_album_id

  data_type: 'integer'
  is_foreign_key: 1
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "person_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 255 },
  "email",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "birthday",
  { data_type => "datetime", is_nullable => 0 },
  "favorite_album_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
);

=head1 PRIMARY KEY

=over 4

=item * L</person_id>

=back

=cut

__PACKAGE__->set_primary_key("person_id");

=head1 UNIQUE CONSTRAINTS

=head2 C<email_unique>

=over 4

=item * L</email>

=back

=cut

__PACKAGE__->add_unique_constraint("email_unique", ["email"]);

=head1 RELATIONS

=head2 albums

Type: has_many

Related object: L<Sample::Schema::Result::Album>

=cut

__PACKAGE__->has_many(
  "albums",
  "Sample::Schema::Result::Album",
  { "foreign.producer_id" => "self.person_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 customer

Type: might_have

Related object: L<Sample::Schema::Result::Customer>

=cut

__PACKAGE__->might_have(
  "customer",
  "Sample::Schema::Result::Customer",
  { "foreign.person_id" => "self.person_id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

=head2 favorite_album

Type: belongs_to

Related object: L<Sample::Schema::Result::Album>

=cut

__PACKAGE__->belongs_to(
  "favorite_album",
  "Sample::Schema::Result::Album",
  { album_id => "favorite_album_id" },
  {
    is_deferrable => 1,
    join_type     => "LEFT",
    on_delete     => "NO ACTION",
    on_update     => "NO ACTION",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07043 @ 2015-06-19 13:13:01
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:H/ykZGjgIBkgXTeBGU47pQ

sub is_customer {
    my $self = shift;
    return defined $self->customer;
}

1;
