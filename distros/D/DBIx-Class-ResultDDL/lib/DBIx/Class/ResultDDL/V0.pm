package DBIx::Class::ResultDDL::V0;
use DBIx::Class::ResultDDL -exporter_setup => 1;
use Carp;

# ABSTRACT: Back-compat for version 0 of this module


my @V0= qw(
	table
	col
	  null default auto_inc fk
	  integer unsigned tinyint smallint bigint decimal numeric
	  char varchar nchar nvarchar binary varbinary blob text ntext
	  date datetime timestamp enum bool boolean
	  inflate_json
	primary_key
	rel_one rel_many has_one might_have has_many belongs_to many_to_many
	  ddl_cascade dbic_cascade
);
our %EXPORT_TAGS;
$EXPORT_TAGS{V0}= \@V0;
export @V0;


sub null       { is_nullable => 1 }
sub auto_inc   { is_auto_increment => 1 }
sub fk         { is_foreign_key => 1 }


sub integer     { data_type => 'integer',   size => (defined $_[0]? $_[0] : 11) }
sub unsigned    { 'extra.unsigned' => 1 }
sub tinyint     { data_type => 'tinyint',   size => 4 }
sub smallint    { data_type => 'smallint',  size => 6 }
sub bigint      { data_type => 'bigint',    size => 22 }
sub decimal     {
	croak "2 size parameters are required" unless scalar(@_) == 2;
	return data_type => 'decimal',   size => [ @_ ];
}
sub numeric     { &decimal, data_type => 'numeric' }


sub char        { data_type => 'char',      size => (defined $_[0]? $_[0] : 1) }
sub nchar       { data_type => 'nchar',     size => (defined $_[0]? $_[0] : 1) }
sub varchar     { data_type => 'varchar',   size => (defined $_[0]? $_[0] : 255) }
sub nvarchar    { data_type => 'nvarchar',  size => (defined $_[0]? $_[0] : 255) }
sub binary      { data_type => 'binary',    size => (defined $_[0]? $_[0] : 255) }
sub varbinary   { data_type => 'varbinary', size => (defined $_[0]? $_[0] : 255) }

sub blob        { data_type => 'blob',      (defined $_[0]? (size => $_[0]) : ()) }
sub tinyblob    { data_type => 'tinyblob',  size => 0xFF }
sub mediumblob  { data_type => 'mediumblob',size => 0xFFFFFF }
sub longblob    { data_type => 'longblob',  size => 0xFFFFFFFF }

sub text        { data_type => 'text',      (defined $_[0]? (size => $_[0]) : ()) }
sub ntext       { data_type => 'ntext',     size => (defined $_[0]? $_[0] : 0x3FFFFFFF) }
sub tinytext    { data_type => 'tinytext',  size => 0xFF }
sub mediumtext  { data_type => 'mediumtext',size => 0xFFFFFF }
sub longtext    { data_type => 'longtext',  size => 0xFFFFFFFF }


sub boolean     { data_type => 'boolean' }
sub bool        { data_type => 'boolean' }
sub bit         { data_type => 'bit',  size => (defined $_[0]? $_[0] : 1) }


sub date        { data_type => 'date',     (@_? (time_zone => $_[0]) : ()) }
sub datetime    { data_type => 'datetime', (@_? (time_zone => $_[0]) : ()) }
sub timestamp   { data_type => 'timestamp',(@_? (time_zone => $_[0]) : ()) }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Class::ResultDDL::V0 - Back-compat for version 0 of this module

=head1 VERSION

version 1.01

=head1 DESCRIPTION

This package provides the ":V0" API functions, for backward compatibility.

It is always best to upgrade your code to the latest API version, resolving any
conflicts that might arise, but this provides stability for old code.

=head1 EXPORTED METHODS

=head2 col

  col $name, @options;
  # becomes...
  __PACKAGE__->add_column($name, { is_nullable => 0, @merged_options });

Define a column.  This calls add_column after sensibly merging all your options.
It defaults the column to not-null for you, but you can override that by saying
C<null> in your options.
You will probably use many of the methods below to build the options for the column:

=over

=item null

  is_nullable => 1

=item auto_inc

  is_auto_increment => 1

=item fk

  is_foreign_key => 1

=item default($value | @value)

  default_value => $value
  default_value => [ @value ] # if more than one param

=item integer, integer($size)

  data_type => 'integer', size => $size // 11

=item unsigned

  extra => { unsigned => 1 }

MySQL specific flag to be combined with C<integer>

=item tinyint

  data_type => 'tinyint', size => 4

=item smallint

  data_type => 'smallint', size => 6

=item bigint

  data_type => 'bigint', size => 22

=item decimal( $whole, $deci )

  data_type => 'decimal', size => [ $whole, $deci ]

=item numeric( $whole, $deci )

  data_type => 'numeric', size => [ $whole, $deci ]

=item char, char($size)

  data_type => 'char', size => $size // 1

=item varchar, varchar($size), varchar(MAX)

  data_type => 'varchar', size => $size // 255

=item nchar

SQL Server specific type for unicode char

=item nvarchar, nvarchar($size), nvarchar(MAX)

SQL Server specific type for unicode character data.

  data_type => 'nvarchar', size => $size // 255

=item MAX

Constant for 'MAX', used by SQL Server for C<< varchar(MAX) >>.

=item binary, binary($size)

  data_type => 'binary', size => $size // 255

=item varbinary, varbinary($size)

  data_type => 'varbinary', size => $size // 255

=item blob, blob($size)

  data_type => 'blob',
  size => $size if defined $size

Note: For MySQL, you need to change the type according to '$size'.  A MySQL blob is C<< 2^16 >>
max length, and probably none of your binary data would be that small.  Consider C<mediumblob>
or C<longblob>, or consider overriding C<< My::Schema::sqlt_deploy_hook >> to perform this
conversion automatically according to which DBMS you are connected to.

For SQL Server, newer versions deprecate C<blob> in favor of C<VARCHAR(MAX)>.  This is another
detail you might take care of in sqlt_deploy_hook.

=item tinyblob

MySQL-specific type for small blobs

  data_type => 'tinyblob', size => 0xFF

=item mediumblob

MySQL-specific type for larger blobs

  data_type => 'mediumblob', size => 0xFFFFFF

=item longblob

MySQL-specific type for the longest supported blob type

  data_type => 'longblob', size => 0xFFFFFFFF

=item text, text($size)

  data_type => 'text',
  size => $size if defined $size

See MySQL notes in C<blob>.  For SQL Server, you might want C<ntext> or C<< varchar(MAX) >> instead.

=item tinytext

  data_type => 'tinytext', size => 0xFF

=item mediumtext

  data_type => 'mediumtext', size => 0xFFFFFF

=item longtext

  data_type => 'longtext', size => 0xFFFFFFFF

=item ntext

SQL-Server specific type for unicode C<text>.  Note that newer versions prefer C<< nvarchar(MAX) >>.

  data_type => 'ntext', size => 0x3FFFFFFF

=item enum( @values )

  data_type => 'enum', extra => { list => [ @values ] }

=item bool, boolean

  data_type => 'boolean'

Note that SQL Server has 'bit' instead.

=item bit, bit($size)

  data_type => 'bit', size => $size // 1

To be database agnostic, consider using 'bool' and override C<< My::Scema::sqlt_deploy_hook >>
to rewrite it to 'bit' when deployed to SQL Server.

=item date, date($timezone)

  data_type => 'date'
  time_zone => $timezone if defined $timezone

=item datetime, datetime($timezone)

  data_type => 'datetime'
  time_zone => $timezone if defined $timezone

=item timestamp, timestamp($timezone)

  date_type => 'timestamp'
  time_zone => $timezone if defined $timezone

=item inflate_json

  serializer_class => 'JSON'

Also adds the component 'InflateColumn::Serializer' to the current package if it wasn't
added already.

=back

=head2 primary_key

  primary_key(@cols)

Shortcut for __PACKAGE__->set_primary_key(@cols)

=head2 belongs_to

  belongs_to $rel_name, $peer_class, $condition, @attr_list;
  belongs_to $rel_name, { colname => "$ResultClass.$colname" }, @attr_list;
  # becomes...
  __PACKAGE__->belongs_to($rel_name, $peer_class, $condition, { @attr_list });

Note that the normal DBIC belongs_to requires conditions to be of the form

  { "foreign.$their_col" => "self.$my_col" }

but all these sugar functions allow it to be written the other way around, and use a table
name in place of "foreign.".

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
  __PACKAGE__->has_one($rel_name, $peer_class, $condition, { @attr_list });

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

=head1 MISSING FUNCTIONALITY

The methods above in most cases allow you to insert plain-old-DBIC notation
where appropriate, instead of relying purely on sugar methods.
If you are missing your favorite column flag or something, feel free to
contribute a patch.

=head1 AUTHOR

Michael Conrad <mconrad@intellitree.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Michael Conrad, IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
