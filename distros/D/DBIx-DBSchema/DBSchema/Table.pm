package DBIx::DBSchema::Table;

use strict;
use Carp;
use DBIx::DBSchema::_util qw(_load_driver _dbh _parse_opt);
use DBIx::DBSchema::Column 0.14;
use DBIx::DBSchema::Index;
use DBIx::DBSchema::ForeignKey 0.13;

our $VERSION = '0.11';
our $DEBUG = 0;

=head1 NAME

DBIx::DBSchema::Table - Table objects

=head1 SYNOPSIS

  use DBIx::DBSchema::Table;

  #new style (preferred), pass a hashref of parameters
  $table = new DBIx::DBSchema::Table (
    {
      name         => "table_name",
      primary_key  => "primary_key",
      columns      => \@dbix_dbschema_column_objects,
      #deprecated# unique      => $dbix_dbschema_colgroup_unique_object,
      #deprecated# 'index'     => $dbix_dbschema_colgroup_index_object,
      indices      => \@dbix_dbschema_index_objects,
      foreign_keys => \@dbix_dbschema_foreign_key_objects,
    }
  );

  #old style (VERY deprecated)
  $table = new DBIx::DBSchema::Table (
    "table_name",
    "primary_key",
    $dbix_dbschema_colgroup_unique_object,
    $dbix_dbschema_colgroup_index_object,
    @dbix_dbschema_column_objects,
  );

  $table->addcolumn ( $dbix_dbschema_column_object );

  $table_name = $table->name;
  $table->name("table_name");

  $primary_key = $table->primary_key;
  $table->primary_key("primary_key");

  #deprecated# $dbix_dbschema_colgroup_unique_object = $table->unique;
  #deprecated# $table->unique( $dbix_dbschema__colgroup_unique_object );

  #deprecated# $dbix_dbschema_colgroup_index_object = $table->index;
  #deprecated# $table->index( $dbix_dbschema_colgroup_index_object );

  %indices = $table->indices;
  $dbix_dbschema_index_object = $indices{'index_name'};
  @all_index_names = keys %indices;
  @all_dbix_dbschema_index_objects = values %indices;

  @column_names = $table->columns;

  $dbix_dbschema_column_object = $table->column("column");

  #preferred
  @sql_statements = $table->sql_create_table( $dbh );
  @sql_statements = $table->sql_create_table( $datasrc, $username, $password );

  #possible problems
  @sql_statements = $table->sql_create_table( $datasrc );
  @sql_statements = $table->sql_create_table;

=head1 DESCRIPTION

DBIx::DBSchema::Table objects represent a single database table.

=head1 METHODS

=over 4

=item new HASHREF

Creates a new DBIx::DBSchema::Table object.  The preferred usage is to pass a
hash reference of named parameters.

  {
    name          => TABLE_NAME,
    primary_key   => PRIMARY_KEY,
    columns       => COLUMNS,
    indices       => INDICES,
    local_options => OPTIONS,
  }

TABLE_NAME is the name of the table.

PRIMARY_KEY is the primary key (may be empty).

COLUMNS is a reference to an array of DBIx::DBSchema::Column objects
(see L<DBIx::DBSchema::Column>).

INDICES is a reference to an array of DBIx::DBSchema::Index objects
(see L<DBIx::DBSchema::Index>), or a hash reference of index names (keys) and
DBIx::DBSchema::Index objects (values).

FOREIGN_KEYS is a references to an array of DBIx::DBSchema::ForeignKey objects
(see L<DBIx::DBSchema::ForeignKey>).

OPTIONS is a scalar of database-specific table options, such as "WITHOUT OIDS"
for Pg or "TYPE=InnoDB" for mysql.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  my $self;
  if ( ref($_[0]) ) {

    $self = shift;
    $self->{column_order} = [ map { $_->name } @{$self->{columns}} ];
    $self->{columns} = { map { $_->name, $_ } @{$self->{columns}} };

    $self->{indices} = { map { $_->name, $_ } @{$self->{indices}} }
       if ref($self->{indices}) eq 'ARRAY';

    $self->{foreign_keys} ||= [];

  } else {

    carp "Old-style $class creation without named parameters is deprecated!";
    #croak "FATAL: old-style $class creation no longer supported;".
    #      " use named parameters";

    my($name,$primary_key,$unique,$index,@columns) = @_;

    my %columns = map { $_->name, $_ } @columns;
    my @column_order = map { $_->name } @columns;

    $self = {
      'name'         => $name,
      'primary_key'  => $primary_key,
      'unique'       => $unique,
      'index'        => $index,
      'columns'      => \%columns,
      'column_order' => \@column_order,
      'foreign_keys' => [],
    };

  }

  #check $primary_key, $unique and $index to make sure they are $columns ?
  # (and sanity check?)

  bless ($self, $class);

  $_->table_obj($self) foreach values %{ $self->{columns} };

  $self;
}

=item new_odbc DATABASE_HANDLE TABLE_NAME

Creates a new DBIx::DBSchema::Table object from the supplied DBI database
handle for the specified table.  This uses the experimental DBI type_info
method to create a table with standard (ODBC) SQL column types that most
closely correspond to any non-portable column types.   Use this to import a
schema that you wish to use with many different database engines.  Although
primary key and (unique) index information will only be imported from databases
with DBIx::DBSchema::DBD drivers (currently MySQL and PostgreSQL), import of
column names and attributes *should* work for any database.

Note: the _odbc refers to the column types used and nothing else - you do not
have to have ODBC installed or connect to the database via ODBC.

=cut

our %create_params = (
#  undef             => sub { '' },
  ''                => sub { '' },
  'max length'      => sub { $_[0]->{PRECISION}->[$_[1]]; },
  'precision,scale' =>
    sub { $_[0]->{PRECISION}->[$_[1]]. ','. $_[0]->{SCALE}->[$_[1]]; }
);

sub new_odbc {
  my( $proto, $dbh, $name) = @_;

  my $driver = _load_driver($dbh);
  my $sth = _null_sth($dbh, $name);
  my $sthpos = 0;

  my $indices_hr =
    ( $driver
        ? eval "DBIx::DBSchema::DBD::$driver->indices(\$dbh, \$name)"
        : {}
    );

  $proto->new({
    'name'        => $name,
    'primary_key' => scalar(eval "DBIx::DBSchema::DBD::$driver->primary_key(\$dbh, \$name)"),

    'columns'     => [
    
      map { 

            my $col_name = $_;

            my $type_info = scalar($dbh->type_info($sth->{TYPE}->[$sthpos]))
              or die "DBI::type_info ". $dbh->{Driver}->{Name}. " driver ".
                     "returned no results for type ".  $sth->{TYPE}->[$sthpos];

            my $length = &{ $create_params{ $type_info->{CREATE_PARAMS} } }
                          ( $sth, $sthpos++ );

            my $default = '';
            if ( $driver ) {
              $default = ${ [
                eval "DBIx::DBSchema::DBD::$driver->column(\$dbh, \$name, \$_)"
              ] }[4];
            }

            DBIx::DBSchema::Column->new({
                'name'    => $col_name,
                #'type'    => "SQL_". uc($type_info->{'TYPE_NAME'}),
                'type'    => $type_info->{'TYPE_NAME'},
                'null'    => $sth->{NULLABLE}->[$sthpos],
                'length'  => $length,          
                'default' => $default,
                #'local'   => # DB-local
            });

          }
          @{$sth->{NAME}}
    
    ],

    #indices
    'indices' => { map { my $indexname = $_;
                         $indexname =>
                           DBIx::DBSchema::Index->new($indices_hr->{$indexname})
                       } 
                       keys %$indices_hr
                 },

  });
}

=item new_native DATABASE_HANDLE TABLE_NAME

Creates a new DBIx::DBSchema::Table object from the supplied DBI database
handle for the specified table.  This uses database-native methods to read the
schema, and will preserve any non-portable column types.  The method is only
available if there is a DBIx::DBSchema::DBD for the corresponding database
engine (currently, MySQL and PostgreSQL).

=cut

sub new_native {
  my( $proto, $dbh, $name) = @_;
  my $driver = _load_driver($dbh);

  my $primary_key =
    scalar(eval "DBIx::DBSchema::DBD::$driver->primary_key(\$dbh, \$name)"),

  my $indices_hr =
  ( $driver
      ? eval "DBIx::DBSchema::DBD::$driver->indices(\$dbh, \$name)"
      : {}
  );

  $proto->new({
    'name'         => $name,
    'primary_key'  => $primary_key,

    'columns'      => [
      map DBIx::DBSchema::Column->new( @{$_} ),
          eval "DBIx::DBSchema::DBD::$driver->columns(\$dbh, \$name)"
    ],

    'indices' => { map { my $indexname = $_;
                         $indexname =>
                           DBIx::DBSchema::Index->new($indices_hr->{$indexname})
                       } 
                       keys %$indices_hr
                 },

    'foreign_keys' => [
      map DBIx::DBSchema::ForeignKey->new( $_ ),
          eval "DBIx::DBSchema::DBD::$driver->constraints(\$dbh, \$name)"
    ],


  });
}

=item addcolumn COLUMN

Adds this DBIx::DBSchema::Column object. 

=cut

sub addcolumn {
  my($self, $column) = @_;
  $column->table_obj($self);
  ${$self->{'columns'}}{$column->name} = $column; #sanity check?
  push @{$self->{'column_order'}}, $column->name;
}

=item delcolumn COLUMN_NAME

Deletes this column.  Returns false if no column of this name was found to
remove, true otherwise.

=cut

sub delcolumn {
  my($self,$column) = @_;
  return 0 unless exists $self->{'columns'}{$column};
  $self->{'columns'}{$column}->table_obj('');
  delete $self->{'columns'}{$column};
  @{$self->{'column_order'}}= grep { $_ ne $column } @{$self->{'column_order'}};  1;
}

=item name [ TABLE_NAME ]

Returns or sets the table name.

=cut

sub name {
  my($self,$value)=@_;
  if ( defined($value) ) {
    $self->{name} = $value;
  } else {
    $self->{name};
  }
}

=item local_options [ OPTIONS ]

Returns or sets the database-specific table options string.

=cut

sub local_options {
  my($self,$value)=@_;
  if ( defined($value) ) {
    $self->{local_options} = $value;
  } else {
    defined $self->{local_options} ? $self->{local_options} : '';
  }
}

=item primary_key [ PRIMARY_KEY ]

Returns or sets the primary key.

=cut

sub primary_key {
  my($self,$value)=@_;
  if ( defined($value) ) {
    $self->{primary_key} = $value;
  } else {
    #$self->{primary_key};
    #hmm.  maybe should untaint the entire structure when it comes off disk 
    # cause if you don't trust that, ?
    $self->{primary_key} =~ /^(\w*)$/ 
      #aah!
      or die "Illegal primary key: ", $self->{primary_key};
    $1;
  }
}

=item columns

Returns a list consisting of the names of all columns.

=cut

sub columns {
  my($self)=@_;
  #keys %{$self->{'columns'}};
  #must preserve order
  @{ $self->{'column_order'} };
}

=item column COLUMN_NAME

Returns the column object (see L<DBIx::DBSchema::Column>) for the specified
COLUMN_NAME.

=cut

sub column {
  my($self,$column)=@_;
  $self->{'columns'}->{$column};
}

=item indices

Returns a list of key-value pairs suitable for assigning to a hash.  Keys are
index names, and values are index objects (see L<DBIx::DBSchema::Index>).

=cut

sub indices {
  my $self = shift;
  exists( $self->{'indices'} )
    ? %{ $self->{'indices'} }
    : ();
}

=item unique_singles

Meet exciting and unique singles using this method!

This method returns a list of column names that are indexed with their own,
unique, non-compond (that's the "single" part) indices.

=cut

sub unique_singles {
  my $self = shift;
  my %indices = $self->indices;

  map { ${ $indices{$_}->columns }[0] }
      grep { $indices{$_}->unique && scalar(@{$indices{$_}->columns}) == 1 }
           keys %indices;
}

=item sql_create_table [ DATABASE_HANDLE | DATA_SOURCE [ USERNAME PASSWORD [ ATTR ] ] ]

Returns a list of SQL statments to create this table.

The data source can be specified by passing an open DBI database handle, or by
passing the DBI data source name, username and password.  

Although the username and password are optional, it is best to call this method
with a database handle or data source including a valid username and password -
a DBI connection will be opened and the quoting and type mapping will be more
reliable.

If passed a DBI data source (or handle) such as `DBI:mysql:database', will use
MySQL- or PostgreSQL-specific syntax.  Non-standard syntax for other engines
(if applicable) may also be supported in the future.

=cut

sub sql_create_table { 
  my($self, $dbh) = ( shift, _dbh(@_) );

  my $driver = _load_driver($dbh);

#should be in the DBD somehwere :/
#  my $saved_pkey = '';
#  if ( $driver eq 'Pg' && $self->primary_key ) {
#    my $pcolumn = $self->column( (
#      grep { $self->column($_)->name eq $self->primary_key } $self->columns
#    )[0] );
##AUTO-INCREMENT#    $pcolumn->type('serial') if lc($pcolumn->type) eq 'integer';
#    $pcolumn->local( $pcolumn->local. ' PRIMARY KEY' );
#    #my $saved_pkey = $self->primary_key;
#    #$self->primary_key('');
#    #change it back afterwords :/
#  }

  my @columns = map { $self->column($_)->line($dbh) } $self->columns;

  push @columns, "PRIMARY KEY (". $self->primary_key. ")"
    if $self->primary_key && ! grep /PRIMARY KEY/i, @columns;

#  push @columns, $self->foreign_keys_sql;

  my $indexnum = 1;

  my @r = (
    "CREATE TABLE ". $self->name. " (\n  ". join(",\n  ", @columns). "\n)\n".
    $self->local_options
  );

  my %indices = $self->indices;
  #push @r, map { $indices{$_}->sql_create_index( $self->name ) } keys %indices;
  foreach my $index ( keys %indices ) {
    push @r, $indices{$index}->sql_create_index( $self->name );
  }

  #$self->primary_key($saved_pkey) if $saved_pkey;
  @r;
}

=item sql_add_constraints [ DATABASE_HANDLE | DATA_SOURCE [ USERNAME PASSWORD [ ATTR ] ] ]

Returns a list of SQL statments to add constraints (foreign keys) to this table.

The data source can be specified by passing an open DBI database handle, or by
passing the DBI data source name, username and password.  

Although the username and password are optional, it is best to call this method
with a database handle or data source including a valid username and password -
a DBI connection will be opened and the quoting and type mapping will be more
reliable.

If passed a DBI data source (or handle) such as `DBI:mysql:database', will use
MySQL- or PostgreSQL-specific syntax.  Non-standard syntax for other engines
(if applicable) may also be supported in the future.

=cut

sub sql_add_constraints {
  my $self = shift;
  my @fks = $self->foreign_keys_sql or return ();
  (
    'ALTER TABLE '. $self->name. ' '. join(",\n  ", map "ADD $_", @fks) 
  );
}

=item sql_alter_table PROTOTYPE_TABLE, [ DATABASE_HANDLE | DATA_SOURCE [ USERNAME PASSWORD [ ATTR ] ] ]

Returns a list of SQL statements to alter this table so that it is identical
to the provided table, also a DBIx::DBSchema::Table object.

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

#gosh, false laziness w/DBSchema::sql_update_schema

sub sql_alter_table {
  my($self, $opt, $new, $dbh) = ( shift, _parse_opt(\@_), shift, _dbh(@_) );

  my $driver = _load_driver($dbh);

  my $table = $self->name;

  my @at = ();
  my @r = ();
  my @r_later = ();
  my $tempnum = 1;

  ###
  # columns (add/alter)
  ###

  foreach my $column ( $new->columns ) {

    if ( $self->column($column) )  {
      warn "  $table.$column exists\n" if $DEBUG > 1;

      my ($alter_table, $sql) = 
        $self->column($column)->sql_alter_column( $new->column($column),
                                                  $dbh,
                                                  $opt,
                                                );
      push @at, @$alter_table;
      push @r, @$sql;

    } else {
      warn "column $table.$column does not exist.\n" if $DEBUG > 1;

      my ($alter_table, $sql) = $new->column($column)->sql_add_column( $dbh );
      push @at, @$alter_table;
      push @r, @$sql;
  
    }
  
  }

  ###
  # indices
  ###

  my %old_indices = $self->indices;
  my %new_indices = $new->indices;

  foreach my $old ( keys %old_indices ) {

    if ( exists( $new_indices{$old} )
         && $old_indices{$old}->cmp( $new_indices{$old} )
       )
    {
      warn "index $table.$old is identical; not changing\n" if $DEBUG > 1;
      delete $old_indices{$old};
      delete $new_indices{$old};

    } elsif ( $driver eq 'Pg' and $dbh->{'pg_server_version'} >= 80000 ) {

      my @same = grep { $old_indices{$old}->cmp_noname( $new_indices{$_} ) }
                      keys %new_indices;

      if ( @same ) {

        #warn if there's more than one?
        my $same = shift @same;

        warn "index $table.$old is identical to $same; renaming\n"
          if $DEBUG > 1;

        my $temp = 'dbs_temp'.$tempnum++;

        push @r, "ALTER INDEX $old RENAME TO $temp";
        push @r_later, "ALTER INDEX $temp RENAME TO $same";

        delete $old_indices{$old};
        delete $new_indices{$same};

      }

    }

  }

  foreach my $old ( keys %old_indices ) {
    warn "removing obsolete index $table.$old ON ( ".
         $old_indices{$old}->columns_sql. " )\n"
      if $DEBUG > 1;
    push @r, "DROP INDEX $old".
             ( $driver eq 'mysql' ? " ON $table" : '');
  }

  foreach my $new ( keys %new_indices ) {
    warn "creating new index $table.$new\n" if $DEBUG > 1;
    push @r, $new_indices{$new}->sql_create_index($table);
  }

  ###
  # columns (drop)
  ###

  foreach my $column ( grep !$new->column($_), $self->columns ) {

    warn "column $table.$column should be dropped.\n" if $DEBUG;

    push @at, $self->column($column)->sql_drop_column( $dbh );

  }

  ###
  # return the statements
  ###

  unshift @r, "ALTER TABLE $table ". join(', ', @at) if @at;

  push @r, @r_later;

  warn join('', map "$_\n", @r)
    if $DEBUG && @r;

  @r;

}

=item sql_alter_constraints PROTOTYPE_TABLE, [ DATABASE_HANDLE | DATA_SOURCE [ USERNAME PASSWORD [ ATTR ] ] ]

Returns a list of SQL statements to alter this table's constraints (foreign
keys) so that they are identical to the provided table, also a
DBIx::DBSchema::Table object.

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

sub sql_alter_constraints {
  my($self, $opt, $new, $dbh) = ( shift, _parse_opt(\@_), shift, _dbh(@_) );

  my $driver = _load_driver($dbh);

  my $table = $self->name;

  my @at = ();

  # foreign keys (add)
  foreach my $foreign_key ( $new->foreign_keys ) {

    next if grep $foreign_key->cmp($_), $self->foreign_keys;

    push @at, 'ADD '. $foreign_key->sql_foreign_key;
  }

  #foreign keys (drop)
  foreach my $foreign_key ( $self->foreign_keys ) {

    next if grep $foreign_key->cmp($_), $new->foreign_keys;
    next unless $foreign_key->constraint;

    push @at, 'DROP CONSTRAINT '. $foreign_key->constraint;
  }

  return () unless @at;
  (
    'ALTER TABLE '. $self->name. ' '. join(",\n  ", @at) 
  );

}

sub sql_drop_table {
  my( $self, $dbh ) = ( shift, _dbh(@_) );

  my $name = $self->name;

  ("DROP TABLE $name");
}

=item foreign_keys_sql

=cut

sub foreign_keys_sql {
  my $self = shift;
  map $_->sql_foreign_key, $self->foreign_keys;
}

=item foreign_keys

Returns a list of foreign keys (DBIx::DBSchema::ForeignKey objects).

=cut

sub foreign_keys {
  my $self = shift;
  exists( $self->{'foreign_keys'} )
    ? @{ $self->{'foreign_keys'} }
    : ();
}


sub _null_sth {
  my($dbh, $table) = @_;
  my $sth = $dbh->prepare("SELECT * FROM $table WHERE 1=0")
    or die $dbh->errstr;
  $sth->execute or die $sth->errstr;
  $sth;
}

=back

=head1 AUTHOR

Ivan Kohler <ivan-dbix-dbschema@420.am>

Thanks to Mark Ethan Trostler <mark@zzo.com> for a patch to allow tables
with no indices.

=head1 COPYRIGHT

Copyright (c) 2000-2007 Ivan Kohler
Copyright (c) 2000 Mail Abuse Prevention System LLC
Copyright (c) 2007-2013 Freeside Internet Services, Inc.
All rights reserved.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 BUGS

sql_create_table() has database-specific foo that probably ought to be
abstracted into the DBIx::DBSchema::DBD:: modules (or no?  it doesn't anymore?).

sql_alter_table() also has database-specific foo that ought to be abstracted
into the DBIx::DBSchema::DBD:: modules.

sql_create_table() may change or destroy the object's data.  If you need to use
the object after sql_create_table, make a copy beforehand.

Some of the logic in new_odbc might be better abstracted into Column.pm etc.

Add methods to get and set specific indices, by name? (like column COLUMN_NAME)

indices method should be a setter, not just a getter?

=head1 SEE ALSO

L<DBIx::DBSchema>, L<DBIx::DBSchema::Column>, L<DBI>,
L<DBIx::DBSchema::Index>, L<DBIx::DBSchema::FoeignKey>

=cut

1;

