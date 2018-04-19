use utf8;
package Test::Schema::Result::MySQLTypeTest;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

=head1 NAME

Test::Schema::Result::TypeTest

=cut

use strict;
use warnings;

use base 'DBIx::Class::Core';

=head1 TABLE: C<type_test>

=cut

__PACKAGE__->table("type_test");

=head1 ACCESSORS

=head2 char

  data_type: 'char'
  is_nullable: 1
  size: 1

=head2 varchar

  data_type: 'varchar'
  is_nullable: 1
  size: 255

=head2 binary

  data_type: 'binary'
  is_nullable: 1
  size: 1

=head2 varbinary

  data_type: 'varbinary'
  is_nullable: 1
  size: 255

=head2 blob

  data_type: 'blob'
  is_nullable: 1

=head2 text

  data_type: 'text'
  is_nullable: 1

=head2 mediumtext

  data_type: 'mediumtext'
  is_nullable: 1

=head2 longtext

  data_type: 'mediumtext'
  is_nullable: 1

=head2 tinytext

  data_type: 'tinytext'
  is_nullable: 1

=head2 enum

  data_type: 'enum'
  extra: {list => ["X","Y","Z"]}
  is_nullable: 1

=head2 set

  data_type: 'set'
  extra: {list => ["X","Y","Z"]}
  is_nullable: 1

=head2 integer

  data_type: 'integer'
  is_nullable: 1

=head2 int

  data_type: 'integer'
  is_nullable: 1

=head2 smallint

  data_type: 'smallint'
  is_nullable: 1

=head2 tinyint

  data_type: 'tinyint'
  is_nullable: 1

=head2 mediumint

  data_type: 'mediumint'
  is_nullable: 1

=head2 bigint

  data_type: 'bigint'
  is_nullable: 1

=head2 decimal

  data_type: 'decimal'
  is_nullable: 1
  size: [4,2]

=head2 numeric

  data_type: 'decimal'
  is_nullable: 1

=head2 float

  data_type: 'float'
  is_nullable: 1

=head2 double

  data_type: 'double precision'
  extra: {unsigned => 1}
  is_nullable: 1

=head2 bit

  data_type: 'bit'
  is_nullable: 1
  size: 1

=head2 json

  data_type: 'json'
  is_nullable: 1

=head2 date

  data_type: 'date'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 datetime

  data_type: 'datetime'
  datetime_undef_if_invalid: 1
  is_nullable: 1

=head2 timestamp

  data_type: 'timestamp'
  datetime_undef_if_invalid: 1
  default_value: current_timestamp
  is_nullable: 0

=head2 time

  data_type: 'time'
  is_nullable: 1

=head2 year

  data_type: 'year'
  is_nullable: 1

=cut

__PACKAGE__->add_columns(
  "char",
  { data_type => "char", is_nullable => 1, size => 1 },
  "varchar",
  { data_type => "varchar", is_nullable => 1, size => 255 },
  "binary",
  { data_type => "binary", is_nullable => 1, size => 1 },
  "varbinary",
  { data_type => "varbinary", is_nullable => 1, size => 255 },
  "blob",
  { data_type => "blob", is_nullable => 1 },
  "text",
  { data_type => "text", is_nullable => 1 },
  "mediumtext",
  { data_type => "mediumtext", is_nullable => 1 },
  "longtext",
  { data_type => "mediumtext", is_nullable => 1 },
  "tinytext",
  { data_type => "tinytext", is_nullable => 0 },
  "enum",
  {
    data_type => "enum",
    extra => { list => ["X", "Y", "Z"] },
    is_nullable => 1,
  },
  "set",
  {
    data_type => "set",
    extra => { list => ["X", "Y", "Z"] },
    is_nullable => 1,
  },
  "integer",
  { data_type => "integer", is_nullable => 1 },
  "int",
  { data_type => "integer", is_nullable => 1 },
  "smallint",
  { data_type => "smallint", is_nullable => 1 },
  "tinyint",
  { data_type => "tinyint", is_nullable => 1 },
  "mediumint",
  { data_type => "mediumint", is_nullable => 1 },
  "bigint",
  { data_type => "bigint", is_nullable => 1 },
  "decimal",
  { data_type => "decimal", is_nullable => 1, size => [4, 2] },
  "numeric",
  { data_type => "decimal", is_nullable => 1 },
  "float",
  { data_type => "float", is_nullable => 1 },
  "double",
  {
    data_type => "double precision",
    extra => { unsigned => 1 },
    is_nullable => 1,
  },
  "bit",
  { data_type => "bit", is_nullable => 1, size => 1 },
  "json",
  { data_type => "json", is_nullable => 1 },
  "date",
  { data_type => "date", datetime_undef_if_invalid => 1, is_nullable => 1 },
  "datetime",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "timestamp",
  {
    data_type => "timestamp",
    datetime_undef_if_invalid => 1,
    default_value => \"current_timestamp",
    is_nullable => 0,
  },
  "time",
  { data_type => "time", is_nullable => 1 },
  "year",
  { data_type => "year", is_nullable => 1 },
);


# Created by DBIx::Class::Schema::Loader v0.07049 @ 2018-04-05 11:06:00
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:YiTEWbJFthcxWTAIVZb3cg


# You can replace this text with custom code or comments, and it will be preserved on regeneration
1;
