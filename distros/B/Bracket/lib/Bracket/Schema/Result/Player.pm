package Bracket::Schema::Result::Player;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bracket::Schema::Result::Player

=cut

__PACKAGE__->table("player");

=head1 ACCESSORS

=head2 id

  data_type: INT
  default_value: undef
  is_auto_increment: 1
  is_nullable: 0
  size: 11

=head2 username

  data_type: VARCHAR
  default_value: undef
  is_nullable: 1
  size: 64

=head2 password

  data_type: TEXT
  default_value: undef
  is_nullable: 0
  size: 65535

=head2 first_name

  data_type: VARCHAR
  default_value: undef
  is_nullable: 0
  size: 16

=head2 last_name

  data_type: VARCHAR
  default_value: undef
  is_nullable: 0
  size: 16

=head2 email

  data_type: VARCHAR
  default_value: undef
  is_nullable: 0
  size: 64

=head2 active

  data_type: INT
  default_value: 1
  is_nullable: 0
  size: 1

=head2 points

  data_type: MEDIUMINT
  default_value: 0
  is_nullable: 0
  size: 9

=cut

__PACKAGE__->add_columns(
  "id",
  {
    data_type => "INT",
    default_value => undef,
    is_auto_increment => 1,
    is_nullable => 0,
    size => 11,
  },
  "username",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 1,
    size => 64,
  },
  "password",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 0,
    size => 65535,
  },
  "first_name",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 16,
  },
  "last_name",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 16,
  },
  "email",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 64,
  },
  "active",
  { data_type => "INT", default_value => 1, is_nullable => 0, size => 1 },
  "points",
  { data_type => "MEDIUMINT", default_value => 0, is_nullable => 0, size => 9 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("player_email", ["email"]);

=head1 RELATIONS

=head2 picks

Type: has_many

Related object: L<Bracket::Schema::Result::Pick>

=cut

__PACKAGE__->has_many(
  "picks",
  "Bracket::Schema::Result::Pick",
  { "foreign.player" => "self.id" },
);

=head2 player_roles

Type: has_many

Related object: L<Bracket::Schema::Result::PlayerRole>

=cut

__PACKAGE__->has_many(
  "player_roles",
  "Bracket::Schema::Result::PlayerRole",
  { "foreign.player" => "self.id" },
);

=head2 region_scores

Type: has_many

Related object: L<Bracket::Schema::Result::RegionScore>

=cut

__PACKAGE__->has_many(
  "region_scores",
  "Bracket::Schema::Result::RegionScore",
  { "foreign.player" => "self.id" },
);

=head2 tokens

Type: has_many

Related object: L<Bracket::Schema::Result::Token>

=cut

__PACKAGE__->has_many(
  "tokens",
  "Bracket::Schema::Result::Token",
  { "foreign.player" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-03-15 11:45:32
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:R91hdhwccshwCohquahcNw


# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->load_components(qw/ EncodedColumn /);
__PACKAGE__->add_columns(
	"password", {
		encode_column       => 1,
#		encode_class        => 'Digest',
#		encode_args         => { algorithm => 'SHA-256', format => 'base64' },
#		encode_check_method => 'check_password',
		encode_class        => 'Crypt::Eksblowfish::Bcrypt',
        encode_args         => { key_nul => 0, cost => 8 },
        encode_check_method => 'check_password',
        # For some reason deploy() wasn't picking up the type or size
        # so we set it here again.
        data_type => 'VARCHAR',
        size => 256,
	}
);
=head2 player_roles

Type: has_many
Related object: L<Bracket::Schema::Result::PlayerRole>

=cut

__PACKAGE__->has_many(
	"player_roles",
	"Bracket::Schema::Result::PlayerRole",
	{ "foreign.player" => "self.id" },
);

=head2 roles

Relationship bridge across PlayerRole to Role

=cut

__PACKAGE__->many_to_many('roles', 'player_roles', 'role');
1;
