package DBIx::DBSchema;

use strict;
use Storable;
use DBIx::DBSchema::_util qw(_load_driver _dbh _parse_opt);
use DBIx::DBSchema::Table 0.08;
use DBIx::DBSchema::Index;
use DBIx::DBSchema::Column;
use DBIx::DBSchema::ForeignKey;

our $VERSION = '0.45';
$VERSION = eval $VERSION; # modperlstyle: convert the string into a number

our $DEBUG = 0;

our $errstr;

=head1 NAME

DBIx::DBSchema - Database-independent schema objects

=head1 SYNOPSIS

  use DBIx::DBSchema;

  $schema = new DBIx::DBSchema @dbix_dbschema_table_objects;
  $schema = new_odbc DBIx::DBSchema $dbh;
  $schema = new_odbc DBIx::DBSchema $dsn, $user, $pass;
  $schema = new_native DBIx::DBSchema $dbh;
  $schema = new_native DBIx::DBSchema $dsn, $user, $pass;

  $schema->save("filename");
  $schema = load DBIx::DBSchema "filename" or die $DBIx::DBSchema::errstr;

  $schema->addtable($dbix_dbschema_table_object);

  @table_names = $schema->tables;

  $DBIx_DBSchema_table_object = $schema->table("table_name");

  @sql = $schema->sql($dbh);
  @sql = $schema->sql($dsn, $username, $password);
  @sql = $schema->sql($dsn); #doesn't connect to database - less reliable

  $perl_code = $schema->pretty_print;
  %hash = eval $perl_code;
  use DBI qw(:sql_types); $schema = pretty_read DBIx::DBSchema \%hash;

=head1 DESCRIPTION

DBIx::DBSchema objects are collections of DBIx::DBSchema::Table objects and
represent a database schema.

This module implements an OO-interface to database schemas.  Using this module,
you can create a database schema with an OO Perl interface.  You can read the
schema from an existing database.  You can save the schema to disk and restore
it in a different process.  You can write SQL CREATE statements statements for
different databases from a single source.  You can transform one schema to
another, adding any necessary new columns, tables, indices and foreign keys.

Currently supported databases are MySQL, PostgreSQL and SQLite.  Sybase and
Oracle drivers are partially implemented.  DBIx::DBSchema will attempt to use
generic SQL syntax for other databases.  Assistance adding support for other
databases is welcomed.  See L<DBIx::DBSchema::DBD>, "Driver Writer's Guide and
Base Class".

=head1 METHODS

=over 4

=item new TABLE_OBJECT, TABLE_OBJECT, ...

Creates a new DBIx::DBSchema object.

=cut

sub new {
  my($proto, @tables) = @_;
  my %tables = map  { $_->name, $_ } @tables; #check for duplicates?

  my $class = ref($proto) || $proto;
  my $self = {
    'tables' => \%tables,
  };

  bless ($self, $class);

}

=item new_odbc DATABASE_HANDLE | DATA_SOURCE USERNAME PASSWORD [ ATTR ]

Creates a new DBIx::DBSchema object from an existing data source, which can be
specified by passing an open DBI database handle, or by passing the DBI data
source name, username, and password.  This uses the experimental DBI type_info
method to create a schema with standard (ODBC) SQL column types that most
closely correspond to any non-portable column types.  Use this to import a
schema that you wish to use with many different database engines.  Although
primary key and (unique) index information will only be read from databases
with DBIx::DBSchema::DBD drivers (currently MySQL and PostgreSQL), import of
column names and attributes *should* work for any database.  Note that this
method only uses "ODBC" column types; it does not require or use an ODBC
driver.

=cut

sub new_odbc {
  my($proto, $dbh) = ( shift, _dbh(@_) );
  $proto->new(
    map { new_odbc DBIx::DBSchema::Table $dbh, $_ } _tables_from_dbh($dbh)
  );
}

=item new_native DATABASE_HANDLE | DATA_SOURCE USERNAME PASSWORD [ ATTR ]

Creates a new DBIx::DBSchema object from an existing data source, which can be
specified by passing an open DBI database handle, or by passing the DBI data
source name, username and password.  This uses database-native methods to read
the schema, and will preserve any non-portable column types.  The method is
only available if there is a DBIx::DBSchema::DBD for the corresponding database engine (currently, MySQL and PostgreSQL).

=cut

sub new_native {
  my($proto, $dbh) = (shift, _dbh(@_) );
  $proto->new(
    map { new_native DBIx::DBSchema::Table ( $dbh, $_ ) } _tables_from_dbh($dbh)
  );
}

=item load FILENAME

Loads a DBIx::DBSchema object from a file.  If there is an error, returns
false and puts an error message in $DBIx::DBSchema::errstr;

=cut

sub load {
  my($proto,$file)=@_; #use $proto ?

  my $self;

  #first try Storable
  eval { $self = Storable::retrieve($file); };

  if ( $@ && $@ =~ /not.*storable/i ) { #then try FreezeThaw
    my $olderror = $@;

    eval "use FreezeThaw;";
    if ( $@ ) {
      $@ = $olderror;
    } else { 
      open(FILE,"<$file")
        or do { $errstr = "Can't open $file: $!"; return ''; };
      my $string = join('',<FILE>);
      close FILE
        or do { $errstr = "Can't close $file: $!"; return ''; };
      ($self) = FreezeThaw::thaw($string);
    }
  }

  unless ( $self ) {
    $errstr = $@;
  }

  $self;

}

=item save FILENAME

Saves a DBIx::DBSchema object to a file.

=cut

sub save {
  #my($self, $file) = @_;
  Storable::nstore(@_);
}

=item addtable TABLE_OBJECT

Adds the given DBIx::DBSchema::Table object to this DBIx::DBSchema.

=cut

sub addtable {
  my($self,$table)=@_;
  $self->{'tables'}->{$table->name} = $table; #check for dupliates?
}

=item tables 

Returns a list of the names of all tables.

=cut

sub tables {
  my($self)=@_;
  keys %{$self->{'tables'}};
}

=item table TABLENAME

Returns the specified DBIx::DBSchema::Table object.

=cut

sub table {
  my($self,$table)=@_;
  $self->{'tables'}->{$table};
}

=item sql [ DATABASE_HANDLE | DATA_SOURCE [ USERNAME PASSWORD [ ATTR ] ] ]

Returns a list of SQL `CREATE' statements for this schema.

The data source can be specified by passing an open DBI database handle, or by
passing the DBI data source name, username and password.  

Although the username and password are optional, it is best to call this method
with a database handle or data source including a valid username and password -
a DBI connection will be opened and used to check the database version as well
as for more reliable quoting and type mapping.  Note that the database
connection will be used passively, B<not> to actually run the CREATE
statements.

If passed a DBI data source (or handle) such as `DBI:mysql:database' or
`DBI:Pg:dbname=database', will use syntax specific to that database engine.
Currently supported databases are MySQL and PostgreSQL.

If not passed a data source (or handle), or if there is no driver for the
specified database, will attempt to use generic SQL syntax.

=cut

sub sql {
  my($self, $dbh) = ( shift, _dbh(@_) );
  ( 
    ( map { $self->table($_)->sql_create_table($dbh); } $self->tables ),
    ( map { $self->table($_)->sql_add_constraints($dbh); } $self->tables ),
  );
}

=item sql_update_schema [ OPTIONS_HASHREF, ] PROTOTYPE_SCHEMA [ DATABASE_HANDLE | DATA_SOURCE [ USERNAME PASSWORD [ ATTR ] ] ]

Returns a list of SQL statements to update this schema so that it is idential
to the provided prototype schema, also a DBIx::DBSchema object.

Right now this method knows how to add new tables and alter existing tables,
including indices.  If specifically requested by passing an options hashref
with B<drop_tables> set true before all other arguments, it will also drop
tables.

See L<DBIx::DBSchema::Table/sql_alter_table>,
L<DBIx::DBSchema::Column/sql_add_column> and
L<DBIx::DBSchema::Column/sql_alter_column> for additional specifics and
limitations.

The data source can be specified by passing an open DBI database handle, or by
passing the DBI data source name, username and password.  

Although the username and password are optional, it is best to call this method
with a database handle or data source including a valid username and password -
a DBI connection will be opened and used to check the database version as well
as for more reliable quoting and type mapping.  Note that the database
connection will be used passively, B<not> to actually run the CREATE
statements.

If passed a DBI data source (or handle) such as `DBI:mysql:database' or
`DBI:Pg:dbname=database', will use syntax specific to that database engine.
Currently supported databases are MySQL and PostgreSQL.

If not passed a data source (or handle), or if there is no driver for the
specified database, will attempt to use generic SQL syntax.

=cut

#gosh, false laziness w/DBSchema::Table::sql_alter_schema

sub sql_update_schema {
  my($self, $opt, $new, $dbh) = ( shift, _parse_opt(\@_), shift, _dbh(@_) );

  my @r = ();
  my @later = ();

  foreach my $table ( $new->tables ) {
  
    if ( $self->table($table) ) {
  
      warn "$table exists\n" if $DEBUG > 1;

      push @r,
        $self->table($table)->sql_alter_table( $new->table($table),
                                                 $dbh, $opt );
      push @later,
        $self->table($table)->sql_alter_constraints( $new->table($table),
                                                       $dbh, $opt );

    } else {
  
      warn "table $table does not exist.\n" if $DEBUG;

      push @r,     $new->table($table)->sql_create_table(    $dbh );
      push @later, $new->table($table)->sql_add_constraints( $dbh );
  
    }
  
  }

  if ( $opt->{'drop_tables'} ) {

    warn "drop_tables enabled\n" if $DEBUG;

    # drop tables not in $new
    foreach my $table ( grep !$new->table($_), $self->tables ) {

      warn "table $table should be dropped.\n" if $DEBUG;

      push @r, $self->table($table)->sql_drop_table( $dbh );

    }

  }

  push @r, @later;

  warn join("\n", @r). "\n"
    if $DEBUG > 1;

  @r;
  
}

=item update_schema [ OPTIONS_HASHREF, ] PROTOTYPE_SCHEMA, DATABASE_HANDLE | DATA_SOURCE [ USERNAME PASSWORD [ ATTR ] ]

Same as sql_update_schema, except actually runs the SQL commands to update
the schema.  Throws a fatal error if any statement fails.

=cut

sub update_schema {
  #my($self, $new, $dbh) = ( shift, shift, _dbh(@_) );
  my($self, $opt, $new, $dbh) = ( shift, _parse_opt(\@_), shift, _dbh(@_) );

  foreach my $statement ( $self->sql_update_schema( $opt, $new, $dbh ) ) {
    $dbh->do( $statement )
      or die "Error: ". $dbh->errstr. "\n executing: $statement";
  }

}

=item pretty_print

Returns the data in this schema as Perl source, suitable for assigning to a
hash.

=cut

sub pretty_print {
  my($self) = @_;

  join("},\n\n",
    map {
      my $tablename = $_;
      my $table = $self->table($tablename);
      my %indices = $table->indices;

      "'$tablename' => {\n".
        "  'columns' => [\n".
          join("", map { 
                         #cant because -w complains about , in qw()
                         # (also biiiig problems with empty lengths)
                         #"    qw( $_ ".
                         #$table->column($_)->type. " ".
                         #( $table->column($_)->null ? 'NULL' : 0 ). " ".
                         #$table->column($_)->length. " ),\n"
                         "    '$_', ".
                         "'". $table->column($_)->type. "', ".
                         "'". $table->column($_)->null. "', ". 
                         "'". $table->column($_)->length. "', ".

                         ( ref($table->column($_)->default)
                             ? "\\'". ${ $table->column($_)->default }. "'"
                             : "'". $table->column($_)->default. "'"
                         ).', '.

                         "'". $table->column($_)->local. "',\n"
                       } $table->columns
          ).
        "  ],\n".
        "  'primary_key' => '". $table->primary_key. "',\n".

        #old style index representation..

        ( 
          $table->{'unique'} # $table->_unique
            ? "  'unique' => [ ". join(', ',
                map { "[ '". join("', '", @{$_}). "' ]" }
                    @{$table->_unique->lol_ref}
              ).  " ],\n"
            : ''
        ).

        ( $table->{'index'} # $table->_index
            ? "  'index' => [ ". join(', ',
                map { "[ '". join("', '", @{$_}). "' ]" }
                    @{$table->_index->lol_ref}
              ). " ],\n"
            : ''
        ).

        #new style indices
        "  'indices' => { ". join( ",\n                 ",

          map { my $iname = $_;
                my $index = $indices{$iname};
                "'$iname' => { \n".
                  ( $index->using
                      ? "              'using'  => '". $index->using ."',\n"
                      : ''
                  ).
                  "                   'unique'  => ". $index->unique .",\n".
                  "                   'columns' => [ '".
                                              join("', '", @{$index->columns} ).
                                              "' ],\n".
                "                 },\n";
              }
              keys %indices

        ). "\n               }, \n".

        #foreign_keys
        "  'foreign_keys' => [ ". join( ",\n                 ",

          map { my $name = $_->constraint;
                "'$name' => { \n".
                "                 },\n";
              }
            $table->foreign_keys

        ). "\n               ], \n"

      ;

    } $self->tables
  ). "}\n";
}

=item pretty_read HASHREF

This method is B<not> recommended.  If you need to load and save your schema
to a file, see the L</load> and L</save> methods.

Creates a schema as specified by a data structure such as that created by
B<pretty_print> method.

=cut

sub pretty_read {
  my($proto, $href) = @_;

  my $schema = $proto->new( map {  

    my $tablename = $_;
    my $info = $href->{$tablename};

    my @columns;
    while ( @{$info->{'columns'}} ) {
      push @columns, DBIx::DBSchema::Column->new(
        splice @{$info->{'columns'}}, 0, 6
      );
    }

    DBIx::DBSchema::Table->new({
      'name'        => $tablename,
      'primary_key' => $info->{'primary_key'},
      'columns'     => \@columns,

      #indices
      'indices'     => [ map { my $idx_info = $info->{'indices'}{$_};
                               DBIx::DBSchema::Index->new({
                                 'name'    => $_,
                                 #'using'   =>
                                 'unique'  => $idx_info->{'unique'},
                                 'columns' => $idx_info->{'columns'},
                               });
                             }
                             keys %{ $info->{'indices'} }
                       ],
    } );

  } (keys %{$href}) );

}

# private subroutines

sub _tables_from_dbh {
  my($dbh) = @_;
  my $driver = _load_driver($dbh);
  my $db_catalog =
    scalar(eval "DBIx::DBSchema::DBD::$driver->default_db_catalog");
  my $db_schema  =
    scalar(eval "DBIx::DBSchema::DBD::$driver->default_db_schema");
  my $sth = $dbh->table_info($db_catalog, $db_schema, '', 'TABLE')
    or die $dbh->errstr;
  #map { $_->{TABLE_NAME} } grep { $_->{TABLE_TYPE} eq 'TABLE' }
  #  @{ $sth->fetchall_arrayref({ TABLE_NAME=>1, TABLE_TYPE=>1}) };
  map { $_->[0] } grep { $_->[1] =~ /^TABLE$/i }
    @{ $sth->fetchall_arrayref([2,3]) };
}

=back

=head1 AUTHORS

Ivan Kohler <ivan-dbix-dbschema@420.am>

Charles Shapiro <charles.shapiro@numethods.com> and Mitchell Friedman
<mitchell.friedman@numethods.com> contributed the start of a Sybase driver.

Daniel Hanks <hanksdc@about-inc.com> contributed the Oracle driver.

Jesse Vincent contributed the SQLite driver and fixes to quiet down
internal usage of the old API.

Slaven Rezic <srezic@cpan.org> contributed column and table dropping, Pg
bugfixes and more.

=head1 CONTRIBUTIONS

Contributions are welcome!  I'm especially keen on any interest in the top
items/projects below under BUGS.

=head1 REPOSITORY

The code is available from our public git repository:

  git clone git://git.freeside.biz/DBIx-DBSchema.git

Or on the web:

  http://freeside.biz/gitweb/?p=DBIx-DBSchema.git
  Or:
  http://freeside.biz/gitlist/DBIx-DBSchema.git

=head1 COPYRIGHT

Copyright (c) 2000-2007 Ivan Kohler
Copyright (c) 2000 Mail Abuse Prevention System LLC
Copyright (c) 2007-2015 Freeside Internet Services, Inc.
All rights reserved.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 BUGS AND TODO

Multiple primary keys are not yet supported.

Foreign keys: need to support dropping, NOT VALID, reverse engineering w/mysql

Need to port and test with additional databases

Each DBIx::DBSchema object should have a name which corresponds to its name
within the SQL database engine (DBI data source).

Need to support "using" index attribute in pretty_read and in reverse
engineering

sql CREATE TABLE output should convert integers
(i.e. use DBI qw(:sql_types);) to local types using DBI->type_info plus a hash
to fudge things

=head2 PRETTY_ BUGS

pretty_print is actually pretty ugly.

pretty_print isn't so good about quoting values...  save/load is a much better
alternative to using pretty_print/pretty_read

pretty_read is pretty ugly too.

pretty_read should *not* create and pass in old-style unique/index indices
when nothing is given in the read.

Perhaps pretty_read should eval column types so that we can use DBI
qw(:sql_types) here instead of externally.

perhaps we should just get rid of pretty_read entirely.  pretty_print is useful
for debugging, but pretty_read is pretty bunk.

=head1 SEE ALSO

L<DBIx::DBSchema::Table>, L<DBIx::DBSchema::Index>,
L<DBIx::DBSchema::Column>, L<DBIx::DBSchema::DBD>,
L<DBIx::DBSchema::DBD::mysql>, L<DBIx::DBSchema::DBD::Pg>, L<FS::Record>,
L<DBI>

=cut

1;

