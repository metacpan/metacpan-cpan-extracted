package DBIx::Class::ResultDDL::V1;
use DBIx::Class::ResultDDL -exporter_setup => 1;
use Carp;

# ABSTRACT: Back-compat for version 0 of this module


my @V1= qw(
  table view
  col
    null default auto_inc fk
    integer unsigned tinyint smallint bigint decimal numeric money
    float float4 float8 double real
    char varchar nchar nvarchar MAX binary varbinary bit varbit
    blob tinyblob mediumblob longblob text tinytext mediumtext longtext ntext bytea
    date datetime timestamp enum bool boolean
    uuid json jsonb inflate_json array
  primary_key idx create_index unique sqlt_add_index sqlt_add_constraint
  rel_one rel_many has_one might_have has_many belongs_to many_to_many
    ddl_cascade dbic_cascade
);

our %EXPORT_TAGS;
$EXPORT_TAGS{V1}= \@V1;
export @V1;


*_maybe_timezone= *DBIx::Class::ResultDDL::_maybe_timezone;
*_maybe_array=    *DBIx::Class::ResultDDL::_maybe_array;
sub datetime    { my $tz= &_maybe_timezone; data_type => 'datetime'.&_maybe_array, ($tz? (time_zone => $tz) : ()), @_ }
sub timestamp   { my $tz= &_maybe_timezone; data_type => 'timestamp'.&_maybe_array,($tz? (time_zone => $tz) : ()), @_ }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::ResultDDL::V1 - Back-compat for version 0 of this module

=head1 DESCRIPTION

This package provides the ":V1" API functions, for backward compatibility.

It is always best to upgrade your code to the latest API version, resolving any
conflicts that might arise, but this provides stability for old code.

=head1 EXPORTED FUNCTIONS

=head2 table

  table 'foo';
  # becomes...
  __PACKAGE__->table('foo');

=head2 col

  col $name, @options;
  # becomes...
  __PACKAGE__->add_column($name, { is_nullable => 0, @merged_options });

Define a column.  This calls add_column after sensibly merging all your options.
It defaults the column to not-null for you, but you can override that by saying
C<null> in your options.
You will probably use many of the methods below to build the options for the column:

=head3 null

  is_nullable => 1

=head3 auto_inc

  is_auto_increment => 1, 'extra.auto_increment_type' => 'monotonic'

(The 'monotonic' bit is required to correctly deploy on SQLite.  You can read the
L<gory details|https://github.com/dbsrgits/sql-translator/pull/26> but the short
version is that SQLite gives you "fake" autoincrement by default, and you only get
real ANSI-style autoincrement if you ask for it.  SQL::Translator doesn't ask for
the extra work by default, but if you're declaring columns by hand expecting it to
be platform-neutral, then you probably want this.  SQLite also requires data_type
"integer", and for it to be the primary key.)

=head3 fk

  is_foreign_key => 1

=head3 default

  # Call:                       Becomes:
  default($value)               default_value => $value
  default(@value)               default_value => [ @value ]

=head3 integer, tinyint, smallint, bigint, unsigned

  integer                       data_type => 'integer',   size => 11
  integer($size)                data_type => 'integer',   size => $size
  integer[]                     data_type => 'integer[]', size => 11
  integer $size,[]              data_type => 'integer[]', size => $size
  
  # MySQL variants
  tinyint                       data_type => 'tinyint',   size => 4
  smallint                      data_type => 'smallint',  size => 6
  bigint                        data_type => 'bigint',    size => 22
  # MySQL specific flag which can be combined with int types
  unsigned                      extra => { unsigned => 1 }

=head3 numeric, decimal

  numeric                       data_type => 'numeric'
  numeric($p)                   data_type => 'numeric', size => [ $p ]
  numeric($p,$s)                data_type => 'numeric', size => [ $p, $s ]
  numeric[]                     data_type => 'numeric[]'
  numeric $p,$s,[]              data_type => 'numeric[]', size => [ $p, $s ]

  # Same API for decimal
  decimal ...                   data_type => 'decimal' ...

=head3 money

  money                         data_type => 'money'
  money[]                       data_type => 'money[]'

=head3 real, float4, double, float8

  real                          data_type => 'real'
  rea[]                         data_type => 'real[]'
  float4                        data_type => 'float4'
  float4[]                      data_type => 'float4[]'
  double                        data_type => 'double precision'
  double[]                      data_type => 'double precision[]'
  float8                        data_type => 'float8'
  float8[]                      data_type => 'float8[]'

=head3 float

  # Call:                       Becomes:
  float                         data_type => 'float'
  float($bits)                  data_type => 'float', size => $bits
  float[]                       data_type => 'float[]'
  float $bits,[]                data_type => 'float[]', size => $bits

SQLServer and Postgres offer this, where C<$bits> is the number of bits of precision
of the mantissa.  Array notation is supported for Postgres.

=head3 char, nchar, bit

  # Call:                       Becomes:
  char                          data_type => 'char', size => 1
  char($size)                   data_type => 'char', size => $size
  char[]                        data_type => 'char[]', size => 1
  char $size,[]                 data_type => 'char[]', size => $size
  
  # Same API for the others
  nchar ...                     data_type => 'nchar' ...
  bit ...                       data_type => 'bit' ...

C<nchar> (SQL Server unicode char array) has an identical API but
returns C<< data_type => 'nchar' >>

Note that Postgres allows C<"bit"> to have a size, like C<char($size)> but SQL Server
uses C<"bit"> only to represent a single bit.

=head3 varchar, nvarchar, binary, varbinary, varbit

  varchar                       data_type => 'varchar'
  varchar($size)                data_type => 'varchar', size => $size
  varchar(MAX)                  data_type => 'varchar', size => "MAX"
  varchar[]                     data_type => 'varchar[]'
  varchar $size,[]              data_type => 'varchar[]', size => $size
  
  # Same API for the others
  nvarchar ...                  data_type => 'nvarchar' ...
  binary ...                    data_type => 'binary' ...
  varbinary ...                 data_type => 'varbinary' ...
  varbit ...                    data_type => 'varbit' ...

Unlike char/varchar relation, C<binary> does not default the size to 1.

=head3 MAX

Constant for C<"MAX">, used by SQL Server for C<< varchar(MAX) >>.

=head3 blob, tinyblob, mediumblob, longblob, bytea

  blob                          data_type => 'blob',
  blob($size)                   data_type => 'blob', size => $size
  
  # MySQL specific variants:
  tinyblob                      data_type => 'tinyblob', size => 0xFF
  mediumblob                    data_type => 'mediumblob', size => 0xFFFFFF
  longblob                      data_type => 'longblob', size => 0xFFFFFFFF

  # Postgres blob type is 'bytea'
  bytea                         data_type => 'bytea'
  bytea[]                       data_type => 'bytea[]'

Note: For MySQL, you need to change the type according to '$size'.  A MySQL blob is C<< 2^16 >>
max length, and probably none of your binary data would be that small.  Consider C<mediumblob>
or C<longblob>, or consider overriding C<< My::Schema::sqlt_deploy_hook >> to perform this
conversion automatically according to which DBMS you are connected to.

For SQL Server, newer versions deprecate C<blob> in favor of C<VARCHAR(MAX)>.  This is another
detail you might take care of in sqlt_deploy_hook.

=head3 text, tinytext, mediumtext, longtext, ntext

  text                          data_type => 'text',
  text($size)                   data_type => 'text', size => $size
  text[]                        data_type => 'text[]'
  
  # MySQL specific variants:
  tinytext                      data_type => 'tinytext', size => 0xFF
  mediumtext                    data_type => 'mediumtext', size => 0xFFFFFF
  longtext                      data_type => 'longtext', size => 0xFFFFFFFF
  
  # SQL Server unicode variant:
  ntext                         data_type => 'ntext', size => 0x3FFFFFFF
  ntext($size)                  data_type => 'ntext', size => $size

See MySQL notes in C<blob>.  For SQL Server, you might want C<ntext> or C<< nvarchar(MAX) >>
instead.  Postgres does not use a size, and allows arrays of this type.

Newer versions of SQL-Server prefer C<< nvarchar(MAX) >> instead of C<ntext>.

=head3 enum

  enum(@values)                 data_type => 'enum', extra => { list => [ @values ] }

This function cannot take pass-through arguments, since every argument is an enum value.

=head3 bool, boolean

  bool                          data_type => 'boolean'
  bool[]                        data_type => 'boolean[]'
  boolean                       data_type => 'boolean'
  boolean[]                     data_type => 'boolean[]'

Note that SQL Server doesn't support 'boolean', the closest being 'bit',
though in postgres 'bit' is used for bitstrings.

=head3 date

  date                          data_type => 'date'
  date[]                        data_type => 'date[]'

=head3 datetime, timestamp

  datetime                      data_type => 'datetime'
  datetime($tz)                 data_type => 'datetime', time_zone => $tz
  datetime[]                    data_type => 'datetime[]'
  datetime $tz, []              data_type => 'datetime[]', time_zone => $tz
  
  # Same API
  timestamp ...                 data_type => 'timestamp', ...

=head3 array

  array($type)                  data_type => $type.'[]'
  array(@dbic_attrs)            data_type => $type.'[]', @other_attrs
  # i.e.
  array numeric(10,3)           data_type => 'numeric[]', size => [10,3]

Declares a postgres array type by appending C<"[]"> to a type name.
The type name can be given as a single string, or as any sugar function that
returns a C<< data_type => $type >> pair of elements.

=head3 uuid

  uuid                          data_type => 'uuid'
  uuid[]                        data_type => 'uuid[]'

=head3 json, jsonb

  json                          data_type => 'json'
  json[]                        data_type => 'json[]'
  jsonb                         data_type => 'jsonb'
  jsonb[]                       data_type => 'jsonb[]'

If C<< -inflate_json >> use-line option was given, this will additionally imply
L</inflate_json>.

=head3 inflate_json

  inflate_json                  serializer_class => 'JSON'

This first loads the DBIC component L<DBIx::Class::InflateColumn::Serializer>
into the current package if it wasn't added already.  Note that that module is
not a dependency of this one and needs to be installed separately.

=head2 primary_key

  primary_key(@cols)

Shortcut for __PACKAGE__->set_primary_key(@cols)

=head2 unique

  unique($name?, \@cols)

Shortucut for __PACKAGE__->add_unique_constraint($name? \@cols)

=head2 belongs_to

  belongs_to $rel_name, $peer_class, $condition, @attr_list;
  belongs_to $rel_name, { colname => "$ResultClass.$colname" }, @attr_list;
  # becomes...
  __PACKAGE__->belongs_to($rel_name, $peer_class, $condition, { @attr_list });

Note that the normal DBIC belongs_to requires conditions to be of the form

  { "foreign.$their_col" => "self.$my_col" }

but all these sugar functions allow it to be written the other way around, and use a
Result Class name in place of "foreign.".  The Result Class may be a fully qualified
package name, or just the final component if it is in the same parent package namespace
as the current package.

=head2 might_have

  might_have $rel_name, $peer_class, $condition, @attr_list;
  might_have $rel_name, { colname => "$ResultClass.$colname" }, @attr_list;
  # becomes...
  __PACKAGE__->might_have($rel_name, $peer_class, $condition, { @attr_list });

=head2 has_one

  has_one $rel_name, $peer_class, $condition, @attr_list;
  has_one $rel_name, { colname => "$ResultClass.$colname" }, @attr_list;
  # becomes...
  __PACKAGE__->has_one($rel_name, $peer_class, $condition, { @attr_list });

=head2 has_many

  has_many $rel_name, $peer_class, $condition, @attr_list;
  has_many $rel_name, { colname => "$ResultClass.$colname" }, @attr_list;
  # becomes...
  __PACKAGE__->has_many($rel_name, $peer_class, $condition, { @attr_list });

=head2 many_to_many

  many_to_many $name => $rel_to_linktable, $rel_from_linktable;
  # becomes...
  __PACKAGE__->many_to_many(@_);

=head2 rel_one

Declares a single-record left-join relation B<without implying ownership>.
Note that the DBIC relations that do imply ownership like C<might_have> I<cause an implied
deletion of the related row> if you delete a row from this table that references it, even if
your schema did not have a cascading foreign key.  This DBIC feature is controlled by the
C<cascading_delete> option, and using this sugar function to set up the relation defaults that
feature to "off".

  rel_one $rel_name, $peer_class, $condition, @attr_list;
  rel_one $rel_name, { $mycol => "$ResultClass.$fcol", ... }, @attr_list;
  # becomes...
  __PACKAGE__->add_relationship(
    $rel_name, $peer_class, { "foreign.$fcol" => "self.$mycol" },
    {
      join_type => 'LEFT',
      accessor => 'single',
      cascade_copy => 0,
      cascade_delete => 0,
      is_depends_on => $is_f_pk, # auto-detected, unless specified
      ($is_f_pk? fk_columns => { $mycol => 1 } : ()),
      @attr_list
    }
  );

=head2 rel_many

  rel_many $name => { $my_col => "$class.$col", ... }, @options;

Same as L</rel_one>, but generates a one-to-many relation with a multi-accessor.

=head2 ddl_cascade

  ddl_cascade;     # same as ddl_cascade("CASCADE");
  ddl_cascade(1);  # same as ddl_cascade("CASCADE");
  ddl_cascade(0);  # same as ddl_cascade("RESTRICT");
  ddl_cascade($mode);

Helper method to generate C<@options> for above.  It generates

  on_update => $mode, on_delete => $mode

This does not affect client-side cascade, and is only used by Schema::Loader to generate DDL
for the foreign keys when the table is deployed.

=head2 dbic_cascade

  dbic_cascade;  # same as dbic_cascade(1)
  dbic_cascade($enabled);

Helper method to generate C<@options> for above.  It generates

  cascade_copy => $enabled, cascade_delete => $enabled

This re-enables the dbic-side cascading that was disabled by default in the C<rel_> functions.

=head2 view

  view $view_name, $view_sql, %options;

Makes the current resultsource into a view. This is used instead of
'table'. Takes two options, 'is_virtual', to make this into a
virtual view, and  'depends' to list tables this view depends on.

Is the equivalent of

  __PACKAGE__->table_class('DBIx::Class::ResultSource::View');
  __PACKAGE__->table($view_name);

  __PACKAGE__->result_source_instance->view_definition($view_sql);
  __PACKAGE__->result_source_instance->deploy_depends_on($options{depends});
  __PACKAGE__->result_source_instance->is_virtual($options{is_virtual});

=head1 INDEXES AND CONSTRAINTS

DBIx::Class doesn't actually track the indexes or constraints on a table.  If you want to add
these to be automatically deployed with your schema, you need an C<sqlt_deploy_hook> function.
This module can create one for you, but does not yet attempt to wrap one that you provide.
(You can of course wrap the one generated by this module using a method modifier from
L<Class::Method::Modifiers>)
The method C<sqlt_deploy_hook> is created in the current package the first time one of these
functions are called.  If it already exists and wasn't created by DBIx::Class::ResultDDL, it
will throw an exception.  The generated method does call C<maybe::next::method> for you.

=head2 sqlt_add_index

This is a direct passthrough to the function L<SQL::Translator::Schema::Table/add_index>,
without any magic.

See notes above about the generated C<sqlt_deploy_hook>.

=head2 sqlt_add_constraint

This is a direct passthrough to the function L<SQL::Translator::Schema::Table/add_constraint>,
without any magic.

See notes above about the generated C<sqlt_deploy_hook>.

=head2 create_index

  create_index $index_name => \@fields, %options;

This is sugar for sqlt_add_index.  It translates to

  sqlt_add_index( name => $index_name, fields => \@fields, options => \%options, (type => ?) );

where the C<%options> are the L<SQL::Translator::Schema::Index/options>, except if
one of the keys is C<type>, then that key/value gets pulled out and used as
L<SQL::Translator::Schema::Index/type>.

=head2 idx

Alias for L</create_index>; lines up nicely with 'col'.

=head1 MISSING FUNCTIONALITY

The methods above in most cases allow you to insert plain-old-DBIC notation
where appropriate, instead of relying purely on sugar methods.
If you are missing your favorite column flag or something, feel free to
contribute a patch.

=head1 THANKS

Thanks to L<Clippard Instrument Laboratory Inc.|http://www.clippard.com/> and
L<Ellis, Partners in Management Solutions|http://www.epmsonline.com/> for
supporting open source, including portions of this module.

=head1 AUTHOR

Michael Conrad <mconrad@intellitree.com>

=head1 VERSION

version 2.03

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Michael Conrad, IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
