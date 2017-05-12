package DBIx::DBSchema::DBD::Oracle;

use strict;
use vars qw($VERSION @ISA %typemap);
use DBIx::DBSchema::DBD;

$VERSION = '0.01';
@ISA = qw(DBIx::DBSchema::DBD);

%typemap = (
  'VARCHAR'         => 'VARCHAR2',
  'SERIAL'          => 'INTEGER',
  'LONG VARBINARY'  => 'BLOB',
  'TIMESTAMP'       => 'DATE',
  'BOOL'            => 'INTEGER'
);

=head1 NAME

DBIx::DBSchema::DBD::Oracle - Oracle native driver for DBIx::DBSchema

=head1 SYNOPSIS

use DBI;
use DBIx::DBSchema;

$dbh = DBI->connect('dbi:Oracle:tns_service_name', 'user','pass');
$schema = new_native DBIx::DBSchema $dbh;

=head1 DESCRIPTION

This module implements a Oracle-native driver for DBIx::DBSchema.

=head1 AUTHOR

Daniel Hanks <hanksdc@about-inc.com>

=cut 

### Return column name, column type, nullability, column length, column default,
### and a field reserved for driver-specific use
sub columns {
  my ($proto, $dbh, $table) = @_;
  return $proto->_column_info($dbh, $table);
}

sub column {
  my ($proto, $dbh, $table, $column) = @_;
  return $proto->_column_info($dbh, $table, $column);
}

sub _column_info {
  my ($proto, $dbh, $table, $column) = @_;
  my $sql = "SELECT column_name, data_type,
                    CASE WHEN nullable = 'Y' THEN 1
                         WHEN nullable = 'N' THEN 0
                         ELSE 1
                    END AS nullable,
                    data_length, data_default, NULL AS reserved
               FROM user_tab_columns
              WHERE table_name = ?";
     $sql .= "  AND column_name = ?" if defined($column);
  if(defined($column)) {
    return $dbh->selectrow_arrayref($sql, undef, $table, $column);
  } else { ### Assume columns
    return $dbh->selectall_arrayref($sql, undef, $table);
  }
}

### This is broken. Primary keys can be comprised of any subset of a tables
### fields, not just one field, as this module assumes.
sub primary_key {
  my ($proto, $dbh, $table) = @_;
  my $sql = "SELECT column_name
               FROM user_constraints uc, user_cons_columns ucc
              WHERE uc.constraint_name = ucc.constraint_name
                AND uc.constraint_type = 'P'
                AND uc.table_name = ?";
  my ($key) = $dbh->selectrow_array($sql, undef, $table);
  return $key;
}

### Wraoper around _index_info
sub unique {
  my ($proto, $dbh, $table) = @_;
  return $proto->_index_info($dbh, $table, 'UNIQUE');
}

### Wrapper around _index_info
sub index {
  my ($proto, $dbh, $table) = @_;
  return $proto->_index_info($dbh, $table, 'NONUNIQUE');
}

### Collect info about unique or non-unique indexes
### $type must be 'UNIQUE' or 'NONUNIQUE'
sub _index_info {
  my ($proto, $dbh, $table, $type) = @_;

  ### Sanity-check
  die "\$type must be 'UNIQUE' or 'NONUNIQUE'" 
    unless $type =~ /^(NON)?UNIQUE$/;

  ### Set up the query
  my $sql = "SELECT ui.index_name, uic.column_name
               FROM user_indexes ui, user_ind_columns uic
              WHERE ui.index_name = uic.index_name
                AND ui.uniqueness = ?
                AND table_name = ?";
  my $sth = $dbh->prepare($sql);
  $sth->execute($table, $type);

  ### Now collect the results
  my $results = {};
  while(my ($idx, $col) = $sth->fetchrow_array()) {
    if(!exists($results->{$idx})) {
      $results->{$idx} = [];
    }
    push @{$results->{$idx}}, $col;
  }
  return $results;
}


