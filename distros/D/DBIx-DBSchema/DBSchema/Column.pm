package DBIx::DBSchema::Column;

use strict;
use vars qw($VERSION);
use Carp;
use DBIx::DBSchema::_util qw(_load_driver _dbh _parse_opt);

$VERSION = '0.14';

=head1 NAME

DBIx::DBSchema::Column - Column objects

=head1 SYNOPSIS

  use DBIx::DBSchema::Column;

  #named params with a hashref (preferred)
  $column = new DBIx::DBSchema::Column ( {
    'name'    => 'column_name',
    'type'    => 'varchar'
    'null'    => 'NOT NULL',
    'length'  => 64,
    'default' => '',
    'local'   => '',
  } );

  #list
  $column = new DBIx::DBSchema::Column ( $name, $sql_type, $nullability, $length, $default, $local );

  $name = $column->name;
  $column->name( 'name' );

  $sql_type = $column->type;
  $column->type( 'sql_type' );

  $null = $column->null;
  $column->null( 'NULL' );
  $column->null( 'NOT NULL' );
  $column->null( '' );

  $length = $column->length;
  $column->length( '10' );
  $column->length( '8,2' );

  $default = $column->default;
  $column->default( 'Roo' );

  $sql_line = $column->line;
  $sql_line = $column->line($datasrc);

  $sql_add_column = $column->sql_add_column;
  $sql_add_column = $column->sql_add_column($datasrc);

=head1 DESCRIPTION

DBIx::DBSchema::Column objects represent columns in tables (see
L<DBIx::DBSchema::Table>).

=head1 METHODS

=over 4

=item new HASHREF

=item new [ name [ , type [ , null [ , length  [ , default [ , local ] ] ] ] ] ]

Creates a new DBIx::DBSchema::Column object.  Takes a hashref of named
parameters, or a list.  B<name> is the name of the column.  B<type> is the SQL
data type.  B<null> is the nullability of the column (intrepreted using Perl's
rules for truth, with one exception: `NOT NULL' is false).  B<length> is the
SQL length of the column.  B<default> is the default value of the column.
B<local> is reserved for database-specific information.

Note: If you pass a scalar reference as the B<default> rather than a scalar value, it will be dereferenced and quoting will be forced off.  This can be used to pass SQL functions such as C<now()> or explicit empty strings as C<''> as
defaults.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  my $self;
  if ( ref($_[0]) ) {
    $self = shift;
  } else {
    #carp "Old-style $class creation without named parameters is deprecated!";
    #croak "FATAL: old-style $class creation no longer supported;".
    #      " use named parameters";

    $self = { map { $_ => shift } qw(name type null length default local) };
  }

  #croak "Illegal name: ". $self->{'name'}
  #  if grep $self->{'name'} eq $_, @reserved_words;

  $self->{'null'} =~ s/^NOT NULL$//i;
  $self->{'null'} = 'NULL' if $self->{'null'};

  bless ($self, $class);

}

=item name [ NAME ]

Returns or sets the column name.

=cut

sub name {
  my($self,$value)=@_;
  if ( defined($value) ) {
  #croak "Illegal name: $name" if grep $name eq $_, @reserved_words;
    $self->{'name'} = $value;
  } else {
    $self->{'name'};
  }
}

=item type [ TYPE ]

Returns or sets the column type.

=cut

sub type {
  my($self,$value)=@_;
  if ( defined($value) ) {
    $self->{'type'} = $value;
  } else {
    $self->{'type'};
  }
}

=item null [ NULL ]

Returns or sets the column null flag (the empty string is equivalent to
`NOT NULL')

=cut

sub null {
  my($self,$value)=@_;
  if ( defined($value) ) {
    $value =~ s/^NOT NULL$//i;
    $value = 'NULL' if $value;
    $self->{'null'} = $value;
  } else {
    $self->{'null'};
  }
}

=item length [ LENGTH ]

Returns or sets the column length.

=cut

sub length {
  my($self,$value)=@_;
  if ( defined($value) ) {
    $self->{'length'} = $value;
  } else {
    $self->{'length'};
  }
}

=item default [ LOCAL ]

Returns or sets the default value.

=cut

sub default {
  my($self,$value)=@_;
  if ( defined($value) ) {
    $self->{'default'} = $value;
  } else {
    $self->{'default'};
  }
}


=item local [ LOCAL ]

Returns or sets the database-specific field.

=cut

sub local {
  my($self,$value)=@_;
  if ( defined($value) ) {
    $self->{'local'} = $value;
  } else {
    $self->{'local'};
  }
}

=item table_obj [ TABLE_OBJ ]

Returns or sets the table object (see L<DBIx::DBSchema::Table>).  Typically
set internally when a column object is added to a table object.

=cut

sub table_obj {
  my($self,$value)=@_;
  if ( defined($value) ) {
    $self->{'table_obj'} = $value;
  } else {
    $self->{'table_obj'};
  }
}

=item table_name

Returns the table name, or the empty string if this column has not yet been
assigned to a table.

=cut

sub table_name {
  my $self = shift;
  $self->{'table_obj'} ? $self->{'table_obj'}->name : '';
}

=item line [ DATABASE_HANDLE | DATA_SOURCE [ USERNAME PASSWORD [ ATTR ] ] ]

Returns an SQL column definition.

The data source can be specified by passing an open DBI database handle, or by
passing the DBI data source name, username and password.  

Although the username and password are optional, it is best to call this method
with a database handle or data source including a valid username and password -
a DBI connection will be opened and the quoting and type mapping will be more
reliable.

If passed a DBI data source (or handle) such as `DBI:mysql:database' or
`DBI:Pg:dbname=database', will use syntax specific to that database engine.
Currently supported databases are MySQL and PostgreSQL.  Non-standard syntax
for other engines (if applicable) may also be supported in the future.

=cut

sub line {
  my($self, $dbh) = ( shift, _dbh(@_) );

  my $driver = $dbh ? _load_driver($dbh) : '';
  my $dbd = "DBIx::DBSchema::DBD::$driver";

  ##
  # type mapping
  ## 

  my %typemap;
  %typemap = eval "\%${dbd}::typemap" if $driver;
  my $type = defined( $typemap{uc($self->type)} )
    ? $typemap{uc($self->type)}
    : $self->type;

  ##
  # callback into the database-specific driver
  ##

  my $hashref = $dbd->column_callback( $dbh, $self->table_name, $self );

  $type = $hashref->{'effective_type'}
    if $hashref->{'effective_type'};

  my $null = $self->null;

  #we seem to do this for mysql/Pg/SQLite, i think this should be the default
  #add something to $hashref if drivers need to overrdide?
  $null ||= "NOT NULL";

  $null =~ s/^NULL$// unless $hashref->{'explicit_null'};

  my $default = $hashref->{'effective_default'} || $self->quoted_default($dbh);
  $default = "DEFAULT $default" if $default ne '';

  my $local = $self->local;
  $local = $hashref->{'effective_local'}
    if $hashref->{'effective_local'};

  ##
  # return column line
  ## 

  join(' ',
    $self->name,
    $type. ( ( defined($self->length) && $self->length )
             ? '('.$self->length.')'
             : ''
           ),
    $null,
    $default,
    ( defined($local) ? $local : ''),
  );

}

=item quoted_default DATABASE_HANDLE

Returns this column's default value quoted for the database.

=cut

sub quoted_default {
  my($self, $dbh) = @_;
  my $driver = $dbh ? _load_driver($dbh) : '';

  return ${$self->default} if ref($self->default);

  my $dbd = "DBIx::DBSchema::DBD::$driver";

  return $dbh->quote($self->default)
    if defined($self->default)
    && $self->default ne ''
    && ref($dbh)
    && $dbd->column_value_needs_quoting($self);
  
  return $self->default;

}

=item sql_add_column [ DBH ]

Returns SQL to add this column to an existing table.  (To create a new table,
see L<DBIx::DBSchema::Table/sql_create_table> instead.)

NOTE: This interface has changed in 0.41

Returns two listrefs.  The first is a list of column alteration SQL fragments
for an ALTER TABLE statement.  The second is a list of full SQL statements that
should be run after the ALTER TABLE statement.

The data source can be specified by passing an open DBI database handle, or by
passing the DBI data source name, username and password.  

Although the username and password are optional, it is best to call this method
with a database handle or data source including a valid username and password -
a DBI connection will be opened and the quoting and type mapping will be more
reliable.

If passed a DBI data source (or handle) such as `DBI:Pg:dbname=database', will
use PostgreSQL-specific syntax.  Non-standard syntax for other engines (if
applicable) may also be supported in the future.

=cut

sub sql_add_column {
  my($self, $dbh) = ( shift, _dbh(@_) );

  die "$self: this column is not assigned to a table"
    unless $self->table_name;

  my $driver = $dbh ? _load_driver($dbh) : '';

  my @alter_table = ();
  my @sql = ();
  my $table = $self->table_name;

  my $dbd = "DBIx::DBSchema::DBD::$driver";
  my $hashref = $dbd->add_column_callback( $dbh, $table, $self );

  my $real_type = '';
  if ( $hashref->{'effective_type'} ) {
    $real_type = $self->type;
    $self->type($hashref->{'effective_type'});
  }

  my $real_null = undef;
  if ( exists($hashref->{'effective_null'}) ) {
    $real_null = $self->null;
    $self->null($hashref->{'effective_null'});
  }

  push @alter_table, "ADD COLUMN ". $self->line($dbh);

  push @sql, @{ $hashref->{'sql_after'} } if $hashref->{'sql_after'};

  push @sql, "ALTER TABLE $table ADD PRIMARY KEY ( ".
             $self->table_obj->primary_key. " )"
    if $self->name eq $self->table_obj->primary_key;

  $self->type($real_type) if $real_type;
  $self->null($real_null) if defined $real_null;

  (\@alter_table, \@sql);

}

=item sql_alter_column PROTOTYPE_COLUMN  [ DATABASE_HANDLE | DATA_SOURCE [ USERNAME PASSWORD [ ATTR ] ] ]

Returns SQL to alter this column so that it is identical to the provided
prototype column, also a DBIx::DBSchema::Column object.

NOTE: This interface has changed in 0.41

Returns two listrefs.  The first is a list of column alteration SQL fragments
for an ALTER TABLE statement.  The second is a list of full SQL statements that
should be run after the ALTER TABLE statement.

Optionally, the data source can be specified by passing an open DBI database
handle, or by passing the DBI data source name, username and password.  

If passed a DBI data source (or handle) such as `DBI:Pg:dbname=database', will
use PostgreSQL-specific syntax.  Non-standard syntax for other engines (if
applicable) may also be supported in the future.

If not passed a data source (or handle), or if there is no driver for the
specified database, will attempt to use generic SQL syntax.

=cut

sub sql_alter_column {
  my($self, $opt, $new, $dbh) = ( shift, _parse_opt(\@_), shift, _dbh(@_) );

  my $table = $self->table_name;
  die "$self: this column is not assigned to a table"
    unless $table;

  my $name = $self->name;

  my $driver = $dbh ? _load_driver($dbh) : '';

  my @alter_table = ();
  my @sql = ();

  my $dbd = "DBIx::DBSchema::DBD::$driver";
  my $hashref = $dbd->alter_column_callback( $dbh, $table, $self, $new );

  if ( $hashref->{'sql_alter'} ) {

    push @sql, $hashref->{'sql_alter'};

  } else {

    # change the name...
    # not yet implemented.  how do we tell which old column it was?

    # change the type...
    if ( $hashref->{'sql_alter_type'} ) {
      push @alter_table, $hashref->{'sql_alter_type'};
    }

    # change nullability...

    if ( $hashref->{'sql_alter_null'} ) {

      push @sql, $hashref->{'sql_alter_null'};

    } else {

      # change nullability from NOT NULL to NULL
      if ( ! $self->null && $new->null ) {
    
        push @alter_table, "ALTER COLUMN $name DROP NOT NULL";
    
      }
    
      # change nullability from NULL to NOT NULL...
      # this one could be more complicated, need to set a DEFAULT value and update
      # the table first...
      if ( $self->null && ! $new->null ) {
    
        push @alter_table, "ALTER COLUMN $name SET NOT NULL";
    
      }

    }

    # change default
    my $old_default = $self->quoted_default($dbh);
    my $new_default = $new->quoted_default($dbh);
    if ( $old_default ne $new_default
         && ( uc($old_default) ne 'NOW()' || uc($new_default) ne 'NOW()' )
       )
    {

      #warn "old default: $old_default / new default: $new_default\n";

      my $alter = "ALTER COLUMN $name";

      if ( $new_default ne '' ) {
        #warn "changing from $old_default to $new_default\n";
        push @alter_table, "$alter SET DEFAULT $new_default";
      } elsif ( $old_default !~ /^nextval/i ) { #Pg-specific :(
        push @alter_table, "$alter DROP DEFAULT";

        push @sql, "UPDATE TABLE $table SET $name = NULL WHERE $name = ''"
          if $opt->{'nullify_default'} && $old_default eq "''" && $new->null;
      }

    }

    # change other stuff... (what next?)

  }

  (\@alter_table, \@sql);

}

=item sql_drop_column [ DBH ] 

Returns SQL to drop this column from an existing table.

NOTE: This interface has changed in 0.41

Returns a list of column alteration SQL fragments for an ALTER TABLE statement. 

The optional database handle or DBI data source/username/password is not yet
used.

=cut

sub sql_drop_column {
 my( $self, $dbh ) = ( shift, _dbh(@_) );
 
 my $table = $self->table_name;
 my $name = $self->name;
 
 ("DROP COLUMN $name"); # XXX what about indexes???
}

=back

=head1 AUTHOR

Ivan Kohler <ivan-dbix-dbschema@420.am>

=head1 COPYRIGHT

Copyright (c) 2000-2006 Ivan Kohler
Copyright (c) 2007-2013 Freeside Internet Services, Inc.
All rights reserved.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 BUGS

The new() method should warn that 
"Old-style $class creation without named parameters is deprecated!"

Better documentation is needed for sql_add_column

sql_alter_column() has database-specific foo that should be abstracted info
DBIx::DBSchema::DBD::Pg

nullify_default option should be documented

=head1 SEE ALSO

L<DBIx::DBSchema::Table>, L<DBIx::DBSchema>, L<DBIx::DBSchema::DBD>, L<DBI>

=cut

1;

