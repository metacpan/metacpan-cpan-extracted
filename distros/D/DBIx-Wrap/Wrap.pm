###############################################################################
# DBIx::Wrap
#
# Copyright (c) 2002 Jonathan A. Waxman <jowaxman@bbl.med.upenn.edu>
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
###############################################################################
package DBIx::Wrap;


use strict;
use vars qw($VERSION);
use DBI;
use Time::Local;

$VERSION = '1.00';


=pod

=head1 NAME

  DBIx::Wrap - Object oriented wrapper around DBI.

=head1 SYNOPSIS

  use DBIx::Wrap;

  my $dsn = "DBI:mysql:database=accounts";
  $db = DBIx::Wrap->new (DSN => $dsn, User => 'jowaxman',
                         Password => 'plipplop');

  # select
  # Return a hash reference.
  $user = $db->select (Table    => 'passwd',
                       Fields   => 'gcos,homedir,shell',
                       Where    => "username='jowaxman'");
  $gcos = $user->{gcos};

  # Set the table.
  $db->table ('employees');

  # Return an array of values.
  @info = $db->select (Fields	=> 'ssn,address,phone',
                       Where    => "ssn='123456789'");
  $ssn = $info[1];

  # iterate
  my $id;
  while (my ($username, $gcos) = $db->each (\$id,
    Tables      => 'passwd,employees',
    Fields      => 'passwd.username,address,phone',
    Where       => "passwd.username=employees.username and
                    employees.status='fulltime'")) {
    # Note, could have done
    #   while (my $employee = $db->each (...
    # to get a hash.
  }

  # insert
  $db->insert (Table    => 'passwd',
               Values   => {username	=> $username,
                            uid		=> $uid,
                            gcos	=> $gcos,
                            ...});

  # delete
  $db->delete (Table    => 'passwd',
               Where    => "username='jowaxman'");

=head1 DESCRIPTION

This module is a wrapper around the DBI database class.  It simplifies
database querying.  You may use this as a base class for a derived class
that operates on a specific kind of database.

=head1 CONSTRUCTOR

You must give the constructor the named parameters DSN, User, and
Password so DBI can connect to the database.

=cut

sub new {
  # Create myself.
  my $proto = shift;

  my $class = ref ($proto) || $proto;
  my $self  = {};
  bless ($self, $class);

  # Get params.
  my %params = @_;

  $self->{_sth}  = {};

  $self->{_dsn}  = $params{DSN};
  $self->{_user} = $params{User};

  $self->{_dbh} = eval {DBI->connect ($self->{_dsn}, $self->{_user}, 
                                      $params{Password},
                                      {RaiseError	=> 0,
                                       PrintError	=> 0})};
  return $proto->error ($@) if $@;
  return $proto->error ($DBIx::errstr) if ! defined $self->{_dbh};

  return $self;
}

=head1 ERROR HANDLING

DBIx::Wrap provides the public method C<error> to do simple error
handling. If an argument is given (the error), it is stored, otherwise,
the stored error is returned.

C<error> may be called as a package method (e.g., C<DBIx::Wrap-E<gt>error
($error);> or as an object method (e.g., C<$db-E<gt>error ($error);>.  If
it is called as a package method, the error is stored as a package
variable.  If it is called as an object method, the error is stored as a
private variable.

=cut

sub error {
  my $self  = shift;
  my $error = shift;

  # If an error given, set it in the object or package.
  # Otherwise, return the error from the object or package.
  if (defined $error) {
    ref ($self) ? $self->{_error} = $error : $self::_error = $error;
    return undef;
  } else {
    return ref ($self) ? $self->{_error} : $self::_error;
  }
}

=pod

=head1 PRIVATE METHODS

=head2 _prepare_sql

  my $sql = $self->_prepare_sql ('select', \%params);

This private method prepares an sql statement given a set of named
parameters.  See the DBI or SQL documentation for more information on
valid SQL phrases.  The following named parameters are used:

=over 4

=item Table or Tables

Specified the database table or tables.  You can fix the table by using 
the
method table (see below).

=item Field or Fields

Single field name or comma separated list of field names.

=item Where

A valid SQL WHERE clause.

=item Values

An anonymous hash containing column name/value pairs.

=item OrderBy

The ordering criteria.

=item Limit

A constraint limiting the number of rows returned.

=back 4

=cut

sub _prepare_sql {
  my $self = shift;
  my ($type, $params) = @_;

  my $table;
  if (exists $self->{_table}) {
    $table = $self->{_table};
  } else {
    if (exists $params->{Table}) {
      $table = $params->{Table};
    } elsif (exists $params->{Tables}) {
      $table = $params->{Tables};
    } elsif ($type ne 'show') {
      return $self->error ("$type: No Table parameter given.");
    }
  }
  my $where   = $params->{Where}   if exists $params->{Where};
  my $orderby = $params->{OrderBy} if exists $params->{OrderBy};
  my $limit   = $params->{Limit}   if exists $params->{Limit};
  my $match   = $params->{Match}   if exists $params->{Match};

  my $sql;
  if ($type eq 'select') {
    my $fields;
    if (exists $params->{Fields}) {
      $fields = $params->{Fields};
    } elsif (exists $params->{Field}) {
      $fields = $params->{Field};
    } else {
      $fields = '*';
    }

    if (defined $match) {
      $fields .= ',' if defined $fields;
      if (defined $params->{Round} && $params->{Round} eq 'yes') {
        $fields .= "ROUND(MATCH $match) AS _score";
      } else {
        $fields .= "MATCH $match AS _score";
      }
      $where .= ' and ' if defined $where;
      $where .= "MATCH $match";
    }

    $sql  = "SELECT $fields FROM $table";
    $sql .= " WHERE $where" if defined $where;
    $sql .= " ORDER BY $orderby" if defined $orderby;
    $sql .= " LIMIT $limit" if defined $limit;

  } elsif ($type eq 'insert') {
    return $self->error ('insert: No Values parameter given.')
      if ! defined $params->{Values};

    $sql = "INSERT INTO $table (";
    my ($col_names, $values);
    foreach my $field (keys %{$params->{Values}}) {
      $col_names .= ',' if defined $col_names;
      $col_names .= $field;
      $values .= ',' if defined $values;
      if (exists $params->{Values}->{$field} &&
          ! defined $params->{Values}->{$field}) {
        # If a CSV database, using null for an empty value will result in
        # absent colons so you must set an empty string value.
        if (exists $self->{_dbh}->{csv_tables}) {
          $values .= "''";
        } else {
          $values .= 'null';
        }
      } else {
        $params->{Values}->{$field} =~ s/'/''/g;
# xxx
        if ($params->{Values}->{$field} =~ /FROM_UNIXTIME/
            || $params->{Values}->{$field} =~ /NOW/) {
          $values .= "$params->{Values}->{$field}";
        } else {
          $values .= "'$params->{Values}->{$field}'";
        }
      }
    }
    $sql .= "$col_names) VALUES ($values)";

  } elsif ($type eq 'update') {
    return $self->error ('insert: No Values parameter given.')
      if ! defined $params->{Values};

    $sql = "UPDATE $table SET ";
    my ($col_names, $values);
    foreach my $field (keys %{$params->{Values}}) {
      $col_names .= ',' if defined $col_names;
      if (exists $params->{Values}->{$field} &&
          ! defined $params->{Values}->{$field}) {
        # If a CSV database, using null for an empty value will result in
        # absent colons so you must set an empty string value.
        if (exists $self->{_dbh}->{csv_tables}) {
          $col_names .= "$field=''";
        } else {
          $col_names .= "$field=null";
        }
      } else {
        $params->{Values}->{$field} =~ s/'/''/g;
        $col_names .= "$field='$params->{Values}->{$field}'";
      }
    }
    $sql .= $col_names;
    $sql .= " WHERE $where" if defined $where;

  } elsif ($type eq 'delete') {
    $sql = "DELETE FROM $table";
    $sql .= " WHERE $where" if defined $where;

  } elsif ($type eq 'describe') {
    my $fields;
    if (exists $params->{Fields}) {
      $fields = $params->{Fields};
    } elsif (exists $params->{Field}) {
      $fields = $params->{Field};
    } else {
      $fields = '%';
    }
    $sql = "DESCRIBE $table '$fields'";

  } elsif ($type eq 'alter') {
    return $self->error ('alter: No Action parameter given.')
      if ! defined $params->{Action};

    my $action = $params->{Action};

    $sql = "ALTER TABLE $params->{Table} ";# . uc $action . " ";

    if ($action eq 'add') {
      my $columns = $params->{Columns} || $params->{Column};

      if (defined $params->{PrimaryKey} && $params->{PrimaryKey}) {
        return $self->error ('alter [ADD PRIMARY KEY]: No Column[s] parameter given.')
          if ! defined $columns;

        $sql .= "ADD PRIMARY KEY $columns";
      } elsif ((defined $params->{Unique}   && $params->{Unique}) ||
               (defined $params->{FullText} && $params->{FullText})) {
        my $add = $params->{Unique} ? 'UNIQUE' : 'FULLTEXT';

        return $self->error ("alter [ADD $add]: No Column[s] parameter given.")
          if ! defined $columns;

        $sql .= "ADD $add";
        $sql .= " $params->{Index}" if defined $params->{Index};
        $sql .= " ($columns)";

      # Index must come after Unique/Fulltext.
      } elsif (defined $params->{Index}) {
        return $self->error ('alter [ADD INDEX]: No Column[s] parameter given.')
          if ! defined $columns;

        $sql .= "ADD INDEX $params->{Index} ($columns)";

      } elsif (defined $params->{Definition}) {
        return $self->error ('alter [ADD]: No Column parameter given.')
          if ! defined $params->{Column};

        $sql .= "ADD $params->{Column} ";
        $sql .= $self->_prepare_definition ($params->{Definition})
          || return $self->error ("alter [ADD]: " . $self->error ());
        $sql .= " $params->{Position}" if defined $params->{Position};
      }

    } elsif ($action eq 'alter') {
      return $self->error ('alter [ALTER]: No Column parameter given.')
        if ! defined $params->{Column};
      return $self->error ('alter [ALTER]: No Default parameter given.')
        if ! exists $params->{Default};

      $sql .= "ALTER $params->{Column}";
# xxx default needs to be a literal.
      $sql .= defined $params->{Default} ? " SET DEFAULT $params->{Default}"
                                         : ' DROP DEFAULT';

    } elsif ($action eq 'change') {
      return $self->error ('alter [CHANGE]: No Column parameter given.')
        if ! defined $params->{Column};
      return $self->error ('alter [CHANGE]: No Definition parameter given.')
        if ! defined $params->{Definition};

      $params->{Definition}->{Column} = $params->{Column}
        if ! defined $params->{Definition}->{Column};

      $sql .= "CHANGE $params->{Column} ";
      $sql .= $self->_prepare_definition ($params->{Definition})
        || return $self->error ("alter [CHANGE]: " . $self->error ());
      
    } elsif ($action eq 'modify') {
      return $self->error ('alter [MODIFY]: No Column parameter given.')
        if ! defined $params->{Column};
      return $self->error ('alter [MODIFY]: No Definition parameter given.')
        if ! defined $params->{Definition};

      $sql .= "MODIFY ";
      $sql .= $self->_prepare_definition ($params->{Definition})
        || return $self->error ("alter [MODIFY]: " . $self->error ());
      $sql .= " " . $params->{Position} if defined $params->{Position};

    } elsif ($action eq 'drop') {
      if (defined $params->{PrimaryKey} && $params->{PrimaryKey}) {
        $sql .= "DROP PRIMARY KEY";

      } elsif (defined $params->{Index}) {
        return $self->error ('alter [DROP INDEX]: No Index parameter given.')
          if ! defined $params->{Index};

        $sql .= "DROP INDEX $params->{Index}";

      } else {
        return $self->error ('alter [DROP]: No Column parameter given.')
          if ! defined $params->{Column};

        $sql .= "DROP $params->{Column}";
      }

    } elsif ($action eq 'disable_keys') {
      $sql .= "DISABLE KEYS";

    } elsif ($action eq 'enable_keys') {
      $sql .= "ENABLE KEYS";

    } elsif ($action eq 'rename') {
      return $self->error ('alter [RENAME]: No NewTable parameter given.')
        if ! defined $params->{NewTable};

      $sql .= "RENAME $params->{NewTable}";

    } elsif ($action eq 'orderby') {
      return $self->error ('alter [ORDER BY]: No Column parameter given.')
        if ! defined $params->{Column};

      $sql .= "ORDER BY $params->{Column}";
    }

  } elsif ($type eq 'show') {
    return $self->error ('show: No Action parameter given.')
      if ! defined $params->{Action};

    my $action = $params->{Action};

    $sql = "SHOW ";

    if ($action eq 'table_status') {
      $sql .= "TABLE STATUS";
      $sql .= " LIKE '$table'" if defined $table;
    }
  }

  return $sql;
}

sub _prepare_definition {
  my $self   = shift;
  my $params = shift;

  my $definition;

  return $self->error ('No Definition Type parameter given.')
    if ! defined $params->{Type};
  return $self->error ('No Definition Length parameter given.')
    if $params->{Type} =~ /^(decimal)|(numeric)|(char)|(varchar)$/i &&
       ! defined $params->{Length};
  return $self->error ('No Definition Decimals parameter given.')
    if ($params->{Type} =~ /^(decimal)|(numeric)$/i ||
        (defined $params->{Length} &&
         $params->{Type} =~ /^(real)|(double)|(float)$/i)) &&
       ! defined $params->{Decimals};
  return $self->error ('No Definition Values parameter given.')
    if $params->{Type} =~ /^(set)|(enum)$/i &&
       (! defined $params->{Values} || ! scalar @{$params->{Values}});

  $definition .= "$params->{Column} " if defined $params->{Column};
  $definition .= "$params->{Type}";
  if (defined $params->{Length}) {
    $definition .= "($params->{Length}";
    $definition .= ",$params->{Decimals}" if defined $params->{Decimals};
    $definition .= ")";
  } elsif (defined $params->{Values}) {
    $definition .= "('" . join ("','", @{$params->{Values}}) . "')";
  }
  $definition .= " UNSIGNED" if defined $params->{Unsigned} && $params->{Unsigned};
  $definition .= " ZEROFILL" if defined $params->{ZeroFill} && $params->{ZeroFill};
  $definition .= " BINARY" if defined $params->{Binary} && $params->{Binary};
  $definition .= " NOT NULL" if defined $params->{Null} && ! $params->{Null};
  $definition .= " DEFAULT $params->{Default}" if defined $params->{Default};
  $definition .= " AUTO_INCREMENT" if defined $params->{AutoIncrement} && $params->{AutoIncrement};
  $definition .= " PRIMARY KEY" if defined $params->{PrimaryKey} && $params->{PrimaryKey};

  return $definition;
}

=pod

=head1 PUBLIC METHODS

=head2 table

  $self->table ('passwd');

This method fixes the table so that you do not have to specify the named
parameter Table in any database method.  This is very useful for repeated
operations on the same table or when deriving a class that operates only
on one table (see DB::passwd, for example).

=cut

sub table {
  my $self = shift;
  my $table = shift;

  $self->{_table} = $table;
}

=pod

=head2 select

  $user = $db->select (Table    => 'passwd',
                       Where    => "username='jowaxman'");
  @info = $db->select (Table    => 'passwd',
                       Fields   => 'gcos,homedir,shell',
                       Where    => "uid=12345");

This method performs an SQL SELECT operation.  See _prepare_sql for the
named parameters that are used.

If returning to a scalar, a reference to a hash containing column
name/value pairs is returned.  If returning to an array, a list of values
in the same order as the fields specified in the named parameter Fields
is returned.  If no named parameter Fields is given, all fields are 
returned.

Note that if multiple entries match the WHERE clause, only the first will
be returned.

=cut

sub select {
  my $self   = shift;
  my %params = @_;

  my $sql = $self->_prepare_sql ('select', \%params)
    || return undef;

  my $sth = $self->{_dbh}->prepare ($sql);
  $sth->execute
    || return $self->error ("Could not execute '$sql': "
                            . $self->{_dbh}->errstr);
  $self->{_error} = undef;

  if (wantarray) {
    my @row = $sth->fetchrow;
    $sth->finish;
    return @row;
  } else {
    my $hashref = $sth->fetchrow_hashref;
    $sth->finish;
    return $hashref;
  }
}

sub selectall {
  my $self   = shift;
  my %params = @_;

  my $sql = $self->_prepare_sql ('select', \%params)
    || return undef;

  my $sth = $self->{_dbh}->prepare ($sql);
  $sth->execute
    || return $self->error ("Could not execute '$sql': "
                            . $self->{_dbh}->errstr);
  $self->{_error} = undef;

  if (wantarray) {
    my @rows;
    while (my @row = $sth->fetchrow) {
      if (scalar (@row) == 1) {
        push (@rows, $row[0]);
      } else {
        push (@rows, \@row);
      }
    }
    $sth->finish;
    return @rows;
  } else {
    my @rows;
    while (my $row = $sth->fetchrow_hashref) {
      push (@rows, $row);
    }
    $sth->finish;
    return \@rows;
  }
}

=pod

=head2 each

  my $id;
  while (my ($username, $gcos) = $db->each (\$id,
                                   Table        => 'passwd',
                                   Fields       => 'username,gcos',
                                 )) {
    # Note, could have done 
    #   while (my $user = $db->each (...
    # to get a hash.
  }

Note that this method is deprecated.  Use the C<iterator> method.

This method is used for iterating through multiple database entries.  See
_prepare_sql for the named parameters used.

You must pass as the first arguement a reference to a scalar to store an
id for the iteration.  This allows iterations to be nested without 
conflict.

=cut

sub each {
  my $self = shift;
  my ($id, %params) = @_;

  my $sth;
  if (defined $$id) {
    $sth = $self->{_sth}->{$$id};
  } else {
    my $sql = $self->_prepare_sql ('select', \%params)
      || return undef;

    $sth = $self->{_dbh}->prepare ($sql);
    $sth->execute
      || return $self->error ("each: Could not execute: '$sql': "
                              . $self->{_dbh}->errstr);
    $self->{_error} = undef;

    $$id = scalar (keys %{$self->{_sth}});
    $self->{_sth}->{$$id} = $sth;
  }

  if (wantarray) {
    my @row = $sth->fetchrow;
    if (! @row) {
      $sth->finish;
      delete $self->{_sth}->{$$id};
    }
    return @row;
  } else {
    my $hashref = $sth->fetchrow_hashref;
    if (! $hashref) {
      $sth->finish;
      delete $self->{_sth}->{$$id};
    }
    return $hashref;
  }
}

=pod

=head2 iterator

  my $iterator = $db->iterator (Table	=> 'passwd',
                                Fields	=> 'username,gcos,homedir',
                                Where	=> "homedir like '/home/j/%");
  while (my ($username, $gcos, $homedir) = $iterator->next ()) {
    ...
  }

This method returns an iterator object used to iterate over multiple rows
returned by an SQL query.  See _prepare_sql for the named parameters used.

The iterator method C<next> is used to return the first or next row.  If
C<next> is called in an array context, an array of column values for the
specified fields is returned.  If C<next> is called in a scalar context, a
reference to a hash containing the name/values of the requested columns is
returned.

=cut

sub iterator {
  my $self   = shift;
  my %params = @_;

  my $sql = $self->_prepare_sql ('select', \%params)
    || return undef;

  my $sth = $self->{_dbh}->prepare ($sql);
  $sth->execute
    || return $self->error ("Could not execute '$sql': "
                            . $self->{_dbh}->errstr);
  $self->{_error} = undef;
  
  my $iterator = DBIx::Wrap::Iterator->new ($sth);

  return $iterator;
}

=pod

=head2 insert

  $db->insert (Table    => 'passwd',
               Values   => {username	=> $username,
                            uid		=> $uid,
                            gcos	=> $gcos,
                            ...});

This method inserts a new entry into a database table.  See _prepare_sql
for the named parameters used.

=cut

sub insert {
  my $self = shift;
  my %params = @_;

  my $sql = $self->_prepare_sql ('insert', \%params)
    || return undef;

  my $sth = $self->{_dbh}->prepare ($sql);
  $sth->execute
    || return $self->error ("Could not execute '$sql': "
                            . $self->{_dbh}->errstr);
  $self->{_error} = undef;

  return 1;
}

=pod

=head2 update

  $db->update (Table    => 'passwd',
               Values   => {username    => $new_username,
                            pwd         => 'x',
                            uid         => $uid,
                            ...},
               Where    => "username='$old_username'");

This method updates an existing entry in a database table.  See
_prepare_sql for the named parameters used.

=cut

sub update {
  my $self = shift;
  my %params = @_;

  my $sql = $self->_prepare_sql ('update', \%params)
    || return undef;

  my $sth = $self->{_dbh}->prepare ($sql);
  $sth->execute
    || return $self->error ("Could not execute '$sql': "
                            . $self->{_dbh}->errstr);
  $self->{_error} = undef;

  return 1;
}

=pod

=head2 delete

  $db->delete (Table    => 'users',
               Where    => "username='jowaxman'");

This method deletes an existing entry from a database table.  See
_prepare_sql for the named parameters used.

=cut

sub delete {
  my $self = shift;
  my %params = @_;

  my $sql = $self->_prepare_sql ('delete', \%params)
    || return undef;

  my $sth = $self->{_dbh}->prepare ($sql);
  $sth->execute
    || return $self->error ("Could not execute '$sql': "
                            . $self->{_dbh}->errstr);
  $self->{_error} = undef;

  return 1;
}

=pod

=head2 show_tables

  my @tables = $db->show_tables ();

This method returns an array containg the table names.

=cut

sub show_tables {
  my $self = shift;

  my $sth = $self->{_dbh}->prepare ('show tables');
  $sth->execute
    || return $self->error ("Could not execute 'SHOW TABLES': "
                            . $self->{_dbh}->errstr);
  $self->{_error} = undef;

  my @tables;
  while (my @row = $sth->fetchrow_array) {
    push (@tables, @row);
  }

  return (@tables);
}

=pod

=head2 describe

  my $table_info = $db->describe (Table => 'users');

This method returns a reference to a hash containing information about 
fields.

=cut

sub describe {
  my $self = shift;
  my %params = @_;

  my $sql = $self->_prepare_sql ('describe', \%params)
    || return undef;

  my $sth = $self->{_dbh}->prepare ($sql);
  $sth->execute
    || return $self->error ("Could not execute '$sql': "
                            . $self->{_dbh}->errstr);
  $self->{_error} = undef;

  my (%table_info, @table_info);
  while (my @row = $sth->fetchrow_array) {
    my %field_info = ();
    my $field = $row[0];
    my $type  = $row[1];
    my $key   = $row[3];

    $field_info{field} = $field if wantarray;
    $field_info{key}   = $key;

    # INT
    if ($type =~ /^int(\(([^)]*)\))?( unsigned)?( zerofill)?/i) {
      $field_info{type}     = 'int';
      $field_info{size}     = $2 if defined $2 && $2 ne '';
      $field_info{unsigned} = 1  if defined $3 && $3 ne '';
      $field_info{zerofill} = 1  if defined $4 && $4 ne '';

    # DATETIME
    } elsif ($type =~ /^datetime/) {
      $field_info{type} = 'datetime';

    # CHAR
    } elsif ($type =~ /^(national )?char\(([^)]*)\)( binary)?/i) {
      $field_info{type} = 'char';
      $field_info{national} = 1  if defined $1 && $1 ne '';
      $field_info{size}     = $2;
      $field_info{binary}   = 1  if defined $3 && $3 ne '';

    # VARCHAR
    } elsif ($type =~ /^(national )?varchar\(([^)]*)\)( binary)?/i) {
      $field_info{type} = 'varchar';
      $field_info{national} = 1  if defined $1 && $1 ne '';
      $field_info{size}     = $2;
      $field_info{binary}   = 1  if defined $3 && $3 ne '';

    # BLOB, TEXT
    } elsif ($type =~ /^blob/i) {
      $field_info{type} = 'blob';
    } elsif ($type =~ /^text/i) {
      $field_info{type} = 'text';

    # MEDIUMBLOB, MEDIUMTEXT
    } elsif ($type =~ /^mediumblob/i) {
      $field_info{type} = 'mediumblob';
    } elsif ($type =~ /^mediumtext/i) {
      $field_info{type} = 'mediumtext';

    # ENUM
    } elsif ($type =~ /^enum\(\'([^)]*)\'\)/i) {
      $field_info{type} = 'enum';
      my @values = split ("','", $1);
      $field_info{values} = \@values;
    }

    if (wantarray) {
      push (@table_info, \%field_info);
    } else {
      $table_info{$field} = \%field_info;
    }
  }

  if (wantarray) {
    return @table_info;
  } else {
    return \%table_info;
  }
}

sub alter {
  my $self   = shift;
  my %params = @_;

  my $sql = $self->_prepare_sql ('alter', \%params)
    || return undef;
#print "$sql\n";

  my $sth = $self->{_dbh}->prepare ($sql);
  $sth->execute
    || return $self->error ("Could not execute '$sql': "
                            . $self->{_dbh}->errstr);
  $self->{_error} = undef;

  return 1;
}

sub show {
  my $self   = shift;
  my %params = @_;

  my $sql = $self->_prepare_sql ('show', \%params)
    || return undef;

  my $sth = $self->{_dbh}->prepare ($sql);
  $sth->execute
    || return $self->error ("Could not execute '$sql': "
                            . $self->{_dbh}->errstr);
  $self->{_error} = undef;

  my (%table_status, @table_status);
  while (my $row = $sth->fetchrow_hashref) {
    if (defined $params{Format}) {
      if ($params{Format} eq 'unix') {
        $row->{Update_time} = $self->date2secs ($row->{Update_time});
      }
    }
    if (wantarray) {
      push (@table_status, $row);
    } else {
      $table_status{$row->{Name}} = $row;
    }
  }

  return wantarray ? @table_status : \%table_status;
}

sub date2secs {
  my $self = shift;
  my $date = shift;

  my ($year, $mon, $mday, $hour, $min, $sec, $secs);

  # Convert database date (0000-00-00 00:00).
  if ($date =~ /^(\d\d\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)$/) {
    $year = $1;
    $mon  = $2;
    $mon--;
    $mday = $3;
    $hour = $4;
    $min  = $5;
    $sec  = $6;

    $secs = timelocal ($sec, $min, $hour, $mday, $mon, $year - 1900);
  }

  return $secs;
}

sub DESTROY {
  my $self = shift;

  # Finish any unfinished statement handles from calls to each.
  foreach (keys %{$self->{_sth}}) {
    $self->{_sth}->{$_}->finish;
  }

  # Disconnect from the database.
  $self->{_dbh}->disconnect () if defined $self->{_dbh};
}


package DBIx::Wrap::Iterator;


sub new {
  # Create myself.
  my $proto = shift;

  my $class = ref ($proto) || $proto;
  my $self  = {};
  bless ($self, $class);

  $self->{_sth} = shift;

  return $self;
}

sub next {
  my $self = shift;

  if (wantarray) {
    my @row = $self->{_sth}->fetchrow;
    $self->{_sth}->finish if ! @row;
    return @row;
  } else {
    my $hashref = $self->{_sth}->fetchrow_hashref;
    $self->{_sth}->finish if ! $hashref;
    return $hashref;
  }
}


1;


__END__

=pod

=head1 AUTHOR

Jonathan Waxman
jowaxman@law.upenn.edu

=head1 COPYRIGHT

Copyright (c) 2002 Jonathan A. Waxman
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
