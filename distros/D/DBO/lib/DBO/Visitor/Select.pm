#------------------------------------------------------------------------------
# DBO::Visitor::Select
#
# DESCRIPTION
#
# AUTHOR
#   Gareth Rees
#
# COPYRIGHT
#   Copyright (c) 1999 Canon Research Centre Europe Ltd.
#
# $Id: Select.pm,v 1.3 1999/06/29 17:09:31 garethr Exp $
#------------------------------------------------------------------------------

use strict;

package DBO::Visitor::Select;
use base qw(DBO::Visitor);
use Class::Multimethods;

multimethod visit_table =>
  qw(DBO::Visitor::Select DBO::Table DBO::Handle::DBI) =>
sub {
  my ($vis, $table, $dbh) = @_;

  my @sql = ("SELECT * FROM", $table->{name}, "WHERE");
  foreach my $col (@{$table->{columns}}) {
    $vis->{sql} = [];
    visit_column($vis, $col, $dbh);
    push @sql, @{$vis->{sql}}, "AND" if @{$vis->{sql}};
  }
  pop @sql;
  my $sql = join ' ', @sql;
  my $sth = $dbh->prepare($sql) or die DBO::Exception
    (PREPARE => "Failed to prepare SQL statement %s: %s.", $sql, $dbh->errstr);
  $sth->execute or die DBO::Exception
    (EXECUTE => "Failed to execute insert: %s.", $dbh->errstr);

  # Fetch all records as hash references
  my @records;
  while (my $record = $sth->fetchrow_hashref) {
    # DBI doesn't promise not to reuse the hash, so take a copy.
    push @records, { %$record };
  }
  \@records;
};

multimethod visit_column =>
  qw(DBO::Visitor::Select DBO::Column::String DBO::Handle::DBI) =>
sub {
  my ($vis, $col, $dbh) = @_;
  my $value = $vis->{record}{$col->{name}};
  push @{$vis->{sql}}, $col->{name},'=',$dbh->quote($value) if defined $value;
};

multimethod visit_column =>
  qw(DBO::Visitor::Select DBO::Column::Number DBO::Handle::DBI) =>
sub {
  my ($vis, $col, $dbh) = @_;
  my $value = $vis->{record}{$col->{name}};
  push @{$vis->{sql}}, $col->{name}, '=', $value if defined $value;
};

1;
