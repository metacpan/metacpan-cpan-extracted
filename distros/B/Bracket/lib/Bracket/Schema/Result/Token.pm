package Bracket::Schema::Result::Token;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bracket::Schema::Result::Token

=cut

__PACKAGE__->table("token");

=head1 ACCESSORS

=head2 player

  data_type: INT
  default_value: undef
  is_foreign_key: 1
  is_nullable: 0
  size: 11

=head2 token

  data_type: VARCHAR
  default_value: undef
  is_nullable: 0
  size: 64

=head2 type

  data_type: VARCHAR
  default_value: undef
  is_nullable: 0
  size: 64

=cut

__PACKAGE__->add_columns(
  "player",
  {
    data_type => "INT",
    default_value => undef,
    is_foreign_key => 1,
    is_nullable => 0,
    size => 11,
  },
  "token",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 64,
  },
  "type",
  {
    data_type => "VARCHAR",
    default_value => undef,
    is_nullable => 0,
    size => 64,
  },
);
__PACKAGE__->set_primary_key("token", "player");

=head1 RELATIONS

=head2 player

Type: belongs_to

Related object: L<Bracket::Schema::Result::Player>

=cut

__PACKAGE__->belongs_to(
  "player",
  "Bracket::Schema::Result::Player",
  { id => "player" },
  {},
);


# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-03-02 17:10:27
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:hFFgfGDEUtR7ndqRU61GPQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
