use utf8;
package PgLogTest::Schema::Result::LogSet;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

PgLogTest::Schema::Result::LogSet

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<LogSet>

=cut

__PACKAGE__->table("LogSet");

=head1 ACCESSORS

=head2 Id

  accessor: 'id'
  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: '"LogSet_Id_seq"'

=head2 Epoch

  accessor: 'epoch'
  data_type: 'integer'
  is_nullable: 0

=head2 Description

  accessor: 'description'
  data_type: 'text'
  is_nullable: 0

=head2 UserId

  accessor: 'user_id'
  data_type: 'integer'
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "Id",
  {
    accessor          => "id",
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "\"LogSet_Id_seq\"",
  },
  "Epoch",
  { accessor => "epoch", data_type => "integer", is_nullable => 0 },
  "Description",
  { accessor => "description", data_type => "text", is_nullable => 0 },
  "UserId",
  { accessor => "user_id", data_type => "integer", is_nullable => 0 },
);

=head1 PRIMARY KEY

=over 4

=item * L</Id>

=back

=cut

__PACKAGE__->set_primary_key("Id");


# Created by DBIx::Class::Schema::Loader v0.07039 @ 2014-08-18 17:42:23
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:/t2Y1gklahzLxYTm23AFWA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
