#------------------------------------------------------------------------------
# DBO::Visitor::Create - create database
#
# DESCRIPTION
#   A visitor class that creates tables in a database.
#
# AUTHOR
#   Gareth Rees
#
# COPYRIGHT
#   Copyright (c) 1999 Canon Research Centre Europe Ltd/
#
# $Id: Create.pm,v 1.2 1999/06/14 17:05:21 garethr Exp $
#------------------------------------------------------------------------------

use strict;
package DBO::Visitor::Create;
use base qw(DBO::Visitor);
use Class::Multimethods;

multimethod visit_table =>
  qw(DBO::Visitor::Create DBO::Table DBO::Handle::DBI) =>
sub {
  my ($vis, $table, $dbh) = @_;
  my @sql = ("CREATE TABLE $table->{name} (");
  foreach my $col (@{$table->{columns}}) {
    $vis->{sql} = [];
    visit_column($vis, $col, $dbh);
    push @sql, @{$vis->{sql}}, "," if @{$vis->{sql}};
  }
  splice @sql, -1, 1, ")";
  $dbh->dosql(@sql);
};

multimethod visit_column =>
  qw(DBO::Visitor::Create DBO::Column::Base DBO::Handle::DBI) =>
sub {
  my ($vis, $col, $dbh) = @_;
};

multimethod visit_column =>
  qw(DBO::Visitor::Create DBO::Column::Integer DBO::Handle::DBI) =>
sub {
  my ($vis, $col, $dbh) = @_;
  push @{$vis->{sql}}, "$col->{name} INT";
  push @{$vis->{sql}}, "NOT NULL" if $col->{not_null};
};

multimethod visit_column =>
  qw(DBO::Visitor::Create DBO::Column::Unsigned DBO::Handle::DBI) =>
sub {
  my ($vis, $col, $dbh) = @_;
  push @{$vis->{sql}}, "$col->{name} INT";
  push @{$vis->{sql}}, "NOT NULL" if $col->{not_null};
};

multimethod visit_column =>
  qw(DBO::Visitor::Create DBO::Column::Char DBO::Handle::DBI) =>
sub {
  my ($vis, $col, $dbh) = @_;
  push @{$vis->{sql}}, "$col->{name} CHAR ($col->{max_length})";
  push @{$vis->{sql}}, "NOT NULL" if $col->{not_null};
};

multimethod visit_column =>
  qw(DBO::Visitor::Create DBO::Column::Text DBO::Handle::DBI) =>
sub {
  my ($vis, $col, $dbh) = @_;
  push @{$vis->{sql}}, "$col->{name} VARCHAR ($col->{max_length})";
  push @{$vis->{sql}}, "NOT NULL" if $col->{not_null};
};


#------------------------------------------------------------------------------
# Method instances for mSQL databases
#------------------------------------------------------------------------------

multimethod visit_table =>
  qw(DBO::Visitor::Create DBO::Table DBO::Handle::DBI::mSQL) =>
sub {
  my ($vis, $table, $dbh) = @_;
  $vis->{sequence} = 0;
  # visit_table($vis, $table, superclass($dbh));
  call_next_method();
  if (@{$table->{keys}}) {
    my @sql = "CREATE INDEX index_$table->{name} ON $table->{name}(";
    foreach my $key (@{$table->{keys}}) {
      push @sql, $key->{name}, ",";
    }
    splice @sql, -1, 1, ")";
    $dbh->dosql(@sql);
  }
  if ($vis->{sequence}) {
    $dbh->dosql("CREATE SEQUENCE ON $table->{name}");
  }
};

multimethod visit_column =>
  qw(DBO::Visitor::Create DBO::Column::Text DBO::Handle::DBI::mSQL) =>
sub {
  my ($vis, $col, $dbh) = @_;
  push @{$vis->{sql}}, "$col->{name} TEXT ($col->{avg_length})";
  push @{$vis->{sql}}, "NOT NULL" if $col->{not_null};
};

multimethod visit_column =>
  qw(DBO::Visitor::Create DBO::Column::Unsigned DBO::Handle::DBI::mSQL) =>
sub {
  my ($vis, $col, $dbh) = @_;
  push @{$vis->{sql}}, "$col->{name} UINT";
  push @{$vis->{sql}}, "NOT NULL" if $col->{not_null};
};

multimethod visit_column =>
  qw(DBO::Visitor::Create DBO::Column::AutoIncrement DBO::Handle::DBI::mSQL) =>
sub {
  my ($vis, $col, $dbh) = @_;
  $vis->{sequence} = 1;
  # visit_column($vis, superclass($col), $dbh);
  call_next_method();
};


#------------------------------------------------------------------------------
# Method instances for MySQL databases.
#------------------------------------------------------------------------------

multimethod visit_table =>
  qw(DBO::Visitor::Create DBO::Table DBO::Handle::DBI::mysql) =>
sub {
  my ($vis, $table, $dbh) = @_;
  my @sql = ("CREATE TABLE $table->{name} (");
  $vis->{sql} = \@sql;
  foreach my $col (@{$table->{columns}}) {
    $vis->{sql} = [];
    visit_column($vis, $col, $dbh);
    push @sql, @{$vis->{sql}}, "," if @{$vis->{sql}};
  }
  if (@{$table->{keys}}) {
    push @sql, "INDEX index_$table->{name} (";
    foreach my $key (@{$table->{keys}}) {
      push @sql, $key->{name}, ",";
    }
    splice @sql, -1, 1, ")", ",";
  }
  splice @sql, -1, 1, ")";
  $dbh->dosql(@sql);
};

multimethod visit_column =>
  qw(DBO::Visitor::Create DBO::Column::Unsigned DBO::Handle::DBI::mysql) =>
sub {
  my ($vis, $col, $dbh) = @_;
  push @{$vis->{sql}}, "$col->{name} INT UNSIGNED";
  push @{$vis->{sql}}, "NOT NULL" if $col->{not_null};
};

multimethod visit_column =>
  qw(DBO::Visitor::Create DBO::Column::AutoIncrement DBO::Handle::DBI::mysql) =>
sub {
  my ($vis, $col, $dbh) = @_;
  # visit_column($vis, superclass($col), $dbh);
  call_next_method();
  push @{$vis->{sql}}, "AUTO_INCREMENT";
};

multimethod visit_column =>
  qw(DBO::Visitor::Create DBO::Column::Text DBO::Handle::DBI::mysql) =>
sub {
  my ($vis, $col, $dbh) = @_;
  my $type;
  if    ($col->{max_length} < 0x100)     { $type = 'TINYTEXT' }
  elsif ($col->{max_length} < 0x10000)   { $type = 'TEXT' }
  elsif ($col->{max_length} < 0x1000000) { $type = 'MEDIUMTEXT' }
  else                                   { $type = 'LONGTEXT' }
  push @{$vis->{sql}}, "$col->{name} $type";
  push @{$vis->{sql}}, "NOT NULL" if $col->{not_null};
};

1;
