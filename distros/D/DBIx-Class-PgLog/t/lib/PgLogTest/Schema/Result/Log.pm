use utf8;
package PgLogTest::Schema::Result::Log;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

PgLogTest::Schema::Result::Log

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<Log>

=cut

__PACKAGE__->table("Log");

=head1 ACCESSORS

=head2 Id

  accessor: 'id'
  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0
  sequence: '"Log_Id_seq"'

=head2 LogSetId

  accessor: 'log_set_id'
  data_type: 'bigint'
  is_nullable: 0

=head2 Epoch

  accessor: 'epoch'
  data_type: 'integer'
  is_nullable: 0

=head2 Table

  accessor: undef
  data_type: 'varchar'
  is_nullable: 0
  size: 128

=head2 TableId

  accessor: 'table_id'
  data_type: 'bigint'
  is_nullable: 0

=head2 TableAction

  accessor: 'table_action'
  data_type: 'enum'
  default_value: 'UPDATE'
  extra: {custom_type_name => "tableactiontype",list => ["INSERT","UPDATE","DELETE"]}
  is_nullable: 0

=head2 Columns

  accessor: undef
  data_type: 'character varying[]'
  is_nullable: 1
  size: 255

=head2 OldValues

  accessor: 'old_values'
  data_type: 'text[]'
  is_nullable: 1

=head2 NewValues

  accessor: 'new_values'
  data_type: 'text[]'
  is_nullable: 1

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
    sequence          => "\"Log_Id_seq\"",
  },
  "LogSetId",
  { accessor => "log_set_id", data_type => "bigint", is_nullable => 0 },
  "Epoch",
  { accessor => "epoch", data_type => "integer", is_nullable => 0 },
  "Table",
  { accessor => undef, data_type => "varchar", is_nullable => 0, size => 128 },
  "TableId",
  { accessor => "table_id", data_type => "bigint", is_nullable => 0 },
  "TableAction",
  {
    accessor      => "table_action",
    data_type     => "enum",
    default_value => "UPDATE",
    extra         => {
                       custom_type_name => "tableactiontype",
                       list => ["INSERT", "UPDATE", "DELETE"],
                     },
    is_nullable   => 0,
  },
  "Columns",
  {
    accessor => undef,
    data_type => "character varying[]",
    is_nullable => 1,
    size => 255,
  },
  "OldValues",
  { accessor => "old_values", data_type => "text[]", is_nullable => 1 },
  "NewValues",
  { accessor => "new_values", data_type => "text[]", is_nullable => 1 },
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
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:G7XGn+RA6uJzKvztYhXgBA


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
