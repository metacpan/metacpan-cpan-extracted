package Schema::Abilities::Result::User;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';

__PACKAGE__->load_components(
  "InflateColumn::DateTime",
  "DateTime::Epoch",
  "TimeStamp",
  "EncodedColumn",
);

=head1 NAME

Schema::Abilities::Result::User

=cut

__PACKAGE__->table("users");

=head1 ACCESSORS

=head2 id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 username

  data_type: 'varchar'
  is_nullable: 0
  size: 40

=head2 name

  data_type: 'varchar'
  is_nullable: 0
  size: 40

=head2 password

  data_type: 'char'
  is_nullable: 0
  size: 40

=head2 email

  data_type: 'varchar'
  is_nullable: 0
  size: 100

=head2 created

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 active

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "username",
  { data_type => "varchar", is_nullable => 0, size => 40 },
  "name",
  { data_type => "varchar", is_nullable => 0, size => 40 },
  "password",
  { data_type => "char", is_nullable => 0, size => 40 },
  "email",
  { data_type => "varchar", is_nullable => 0, size => 100 },
  "created",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "active",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("username_unique", ["username"]);

=head1 RELATIONS

=head2 user_roles

Type: has_many

Related object: L<Schema::Abilities::Result::UserRole>

=cut

__PACKAGE__->has_many(
  "user_roles",
  "Schema::Abilities::Result::UserRole",
  { "foreign.user_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);


# Created by DBIx::Class::Schema::Loader v0.07010 @ 2011-10-17 10:52:30
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:LfU+tTgwQl5x69IjYSck0g


__PACKAGE__->add_columns(
                         "password" => {
                                        data_type           => "CHAR",
                                        is_nullable         => 0,
                                        size                => 40,
                                        encode_column       => 1,
                                        encode_class        => 'Digest',
                                        encode_args         => { algorithm => 'SHA-1', format => 'hex' },
                                        encode_check_method => 'check_password',
                                       },
                         "created",
                         {
                          data_type     => "timestamp",
                          is_nullable   => 0,
                          inflate_datetime => 'epoch',
                          set_on_create    => 1,
                         },
                        );

__PACKAGE__->has_many(map_user_role => 'Schema::Abilities::Result::UserRole', 'user_id',
                      { cascade_copy => 0, cascade_delete => 0 });

__PACKAGE__->many_to_many(user_roles => 'map_user_role', 'role');

__PACKAGE__->has_many(map_user_action => 'Schema::Abilities::Result::UserAction', 'user_id',
                      { cascade_copy => 0, cascade_delete => 0 });

__PACKAGE__->many_to_many(actions => 'map_user_action', 'action');


__PACKAGE__->meta->make_immutable;
1;
