package Bracket::Schema::Result::Session;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';


=head1 NAME

Bracket::Schema::Result::Session

=cut

__PACKAGE__->table("session");

=head1 ACCESSORS

=head2 id

  data_type: CHAR
  default_value: undef
  is_nullable: 0
  size: 72

=head2 session_data

  data_type: TEXT
  default_value: undef
  is_nullable: 1
  size: 65535

=head2 expires

  data_type: INT
  default_value: undef
  is_nullable: 1
  size: 11

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "CHAR", default_value => undef, is_nullable => 0, size => 72 },
  "session_data",
  {
    data_type => "TEXT",
    default_value => undef,
    is_nullable => 1,
    size => 65535,
  },
  "expires",
  { data_type => "INT", default_value => undef, is_nullable => 1, size => 11 },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.05003 @ 2010-03-02 09:36:49
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:x4DzAiFfNb9AYzwhu+NKHA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
