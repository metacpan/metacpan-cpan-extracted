#------------------------------------------------------------------------------
# DBO::Visitor::Insert
#
# DESCRIPTION
#
# AUTHOR
#   Gareth Rees
#
# COPYRIGHT
#   Copyright (c) 1999 Canon Research Centre Europe Ltd.
#
# $Id: Insert.pm,v 1.2 1999/06/29 17:09:31 garethr Exp $
#------------------------------------------------------------------------------

use strict;

# We maintain a cache of prepared SQL statements accessible on a
# combination of Table and Handle.  The prepared statement can be
# retrieved and executed quickly.

my %INSERT_STH;

package DBO::Visitor::PrepareInsert;
use base qw(DBO::Visitor);
use Class::Multimethods;

multimethod visit_table =>
  qw(DBO::Visitor::PrepareInsert DBO::Table DBO::Handle::DBI) =>
sub {
  my ($vis, $table, $dbh) = @_;
  my @sql = ("INSERT INTO", $table->{name}, "(");
  my $cols = 0;
  foreach my $col (@{$table->{columns}}){
    $vis->{sql} = [];
    visit_column($vis, $col, $dbh);
    if (@{$vis->{sql}}) {
      ++ $cols;
      push @sql, @{$vis->{sql}}, ",";
    }
  }
  $cols or die DBO::Exception
    (NO_COLUMNS => "No columns found while preparing insert statement");
  splice @sql, -1, 1, ") VALUES (", ("?",",") x $cols;
  splice @sql, -1, 1, ")";
  my $sql = join ' ', @sql;
  $INSERT_STH{$table,$dbh} = $dbh->prepare($sql) or die DBO::Exception
    (PREPARE => "Failed to prepare SQL statement %s: %s.", $sql, $dbh->errstr);
};

multimethod visit_column =>
  qw(DBO::Visitor::PrepareInsert DBO::Column::Base DBO::Handle::DBI) =>
sub {
  my ($vis, $col, $dbh) = @_;
  push @{$vis->{sql}}, $col->{name};
};

package DBO::Visitor::Insert;
use base qw(DBO::Visitor);
use Class::Multimethods;

multimethod visit_table =>
  qw(DBO::Visitor::Insert DBO::Table DBO::Handle::DBI) =>
sub {
  my ($vis, $table, $dbh) = @_;
  my $sth = $INSERT_STH{$table,$dbh}
    || visit_table(DBO::Visitor::PrepareInsert->new, $table, $dbh);
  $sth->execute(map { visit_column($vis, $_, $dbh) } @{$table->{columns}})
    or die DBO::Exception
      (EXECUTE => "Failed to execute insert: %s.", $dbh->errstr);
  $sth->finish;
};

multimethod visit_column =>
  qw(DBO::Visitor::Insert DBO::Column::Base DBO::Handle::DBI) =>
sub {
  my ($vis, $col, $dbh) = @_;
  $vis->{record}{$col->{name}};
};


#------------------------------------------------------------------------------
# Method instances for mSQL databases
#------------------------------------------------------------------------------

multimethod visit_table =>
  qw(DBO::Visitor::Insert DBO::Table DBO::Handle::DBI::mSQL) =>
sub {
  my ($vis, $table, $dbh) = @_;
  # Discover the new value of the sequence, if any.
  if ($table->{autoincrement}) {
    my $sql = "SELECT _seq FROM $table->{name}";
    my @seq = $dbh->selectrow_array($sql) or die DBO::Exception
      (SELECTALL => "Failed to execute SQL statement %s: %s.", $sql, $dbh->errstr);
    $vis->{record}{$table->{autoincrement}} = $seq[0];
  }
  # visit_table($vis, $table, superclass($dbh));
  call_next_method();
};


#------------------------------------------------------------------------------
# Method instances for MySQL databases.
#------------------------------------------------------------------------------

my %MYSQL_STH;

multimethod visit_table =>
  qw(DBO::Visitor::Insert DBO::Table DBO::Handle::DBI::mysql) =>
sub {
  my ($vis, $table, $dbh) = @_;
  # visit_table($vis, $table, superclass($dbh));
  call_next_method();
  # Find out the new value of the autoincrement field, if any.
  if ($table->{autoincrement}) {
    my $sth = $MYSQL_STH{$table,$dbh} || do {
      my $sql = "SELECT $table->{autoincrement} FROM $table->{name} WHERE $table->{autoincrement} IS NULL";
      $MYSQL_STH{$table,$dbh} = $dbh->prepare($sql) or die DBO::Exception
	(PREPARE => "Failed to prepare SQL statement %s: %s.", $sql,
	 $dbh->errstr);
    };
    $sth->execute or die DBO::Exception
      (EXECUTE => "Failed to select autoincrement column: %s.", $dbh->errstr);
    $vis->{record}{$table->{autoincrement}} = $sth->fetchrow_array;
    $sth->finish;
  }
};

multimethod visit_column =>
  qw(DBO::Visitor::Insert DBO::Column::AutoIncrement DBO::Handle::DBI::mysql) =>
sub {
  my ($vis, $col, $dbh) = @_;
  undef; # MySQL turns the NULL value into the next unused integer
};

1;
