#------------------------------------------------------------------------------
# DBO::Visitor::Initialize - Initialize database representation
#
# DESCRIPTION
#   A visitor class that performs various checks and initializations on
#   a DBO database schema representation.
#
# AUTHOR
#   Gareth Rees
#
# COPYRIGHT
#   Copyright (c) 1999 Canon Research Centre Europe Ltd/
#
# $Id: Initialize.pm,v 1.3 1999/06/29 17:09:31 garethr Exp $
#------------------------------------------------------------------------------

use strict;
package DBO::Visitor::Initialize;
use base qw(DBO::Visitor);
use Class::Multimethods qw(visit_database visit_table visit_column);

multimethod visit_database =>
  qw(DBO::Visitor::Initialize DBO::Database DBO::Handle) =>
sub {
  my ($vis, $db, $handle) = @_;
  # visit_database(superclass($vis), $db, $handle);
  call_next_method();
  foreach my $table (@{$db->{tables}}) {
    not exists $db->{tables_by_id}{$table->{id}}
      or die DBO::Exception->new
	(ID_REUSED => "Two tables have same id '%s'.", $table->{id});
    $db->{tables_by_id}{$table->{id}} = $table;
  }
};

multimethod visit_table =>
  qw(DBO::Visitor::Initialize DBO::Table DBO::Handle) =>
sub {
  my ($vis, $table, $handle) = @_;
  $table->{name} or die DBO::Exception->new
    (NO_TABLE_NAME => "No 'name' property for table.");
  $table->{id} or $table->{id} = $table->{name};
  $vis->{keys} = $table->{keys} = [];
  delete $vis->{autoincrement};
  # visit_table(superclass($vis), $table, $handle);
  call_next_method();
  $table->{autoincrement} = $vis->{autoincrement} if $vis->{autoincrement};
  foreach my $col (@{$table->{columns}}) {
    $table->{columns_by_name}{$col->{name}} = $col;
  }
};

multimethod visit_column =>
  qw(DBO::Visitor::Initialize DBO::Column::Base DBO::Handle) =>
sub {
  my ($vis, $col, $handle) = @_;
  $col->{name} or die DBO::Exception->new
    (NO_COLUMN_NAME => "No 'name' property for column.");
};

multimethod visit_column =>
  qw(DBO::Visitor::Initialize DBO::Column::Modifier DBO::Handle) =>
sub {
  my ($vis, $col, $handle) = @_;
  $col->{base} or die DBO::Exception->new
    (NO_BASE_COLUMN => "No base column for modifier.");
  $col->{base}->isa('DBO::Column') or die DBO::Exception->new
    (BASE_COLUMN_TYPE => "Base column for modifier is %s, not a DBO::Column.",
     ref $col->{base});
  visit_column($vis, $col->{base}, $handle);
  $col->{name} = $col->{base}{name};
};

multimethod visit_column =>
  qw(DBO::Visitor::Initialize DBO::Column::Key DBO::Handle) =>
sub {
  my ($vis, $col, $handle) = @_;
  push @{$vis->{keys}}, $col;
  # visit_column($vis, superclass($col), $handle);
  call_next_method();
};

multimethod visit_column =>
  qw(DBO::Visitor::Initialize DBO::Column::AutoIncrement DBO::Handle) =>
sub {
  my ($vis, $col, $handle) = @_;
  # visit_column($vis, superclass($col), $handle);
  call_next_method();
  not exists $vis->{autoincrement} or die DBO::Exception
    (MULTIPLE_AUTOINCREMENT => "Two autoincrement fields (%s and %s) in table are not supported.", $vis->{autoincrement}, $col->{name});
  $vis->{autoincrement} = $col->{name};
};

multimethod visit_column =>
  qw(DBO::Visitor::Initialize DBO::Column::Char DBO::Handle) =>
sub {
  my ($vis, $col, $handle) = @_;
  # visit_column($vis, superclass($col), $handle);
  call_next_method();
  defined $col->{max_length} or $col->{max_length} = 10;
};

multimethod visit_column =>
  qw(DBO::Visitor::Initialize DBO::Column::Text DBO::Handle) =>
sub {
  my ($vis, $col, $handle) = @_;
  # visit_column($vis, superclass($col), $handle);
  call_next_method();
  defined $col->{avg_length} or $col->{avg_length} = 100;
  defined $col->{max_length} or $col->{max_length} = 1000;
};

multimethod visit_column =>
  qw(DBO::Visitor::Initialize DBO::Column::Time DBO::Handle) =>
sub {
  my ($vis, $col, $handle) = @_;
  $col->{max_length} = 19;
  # visit_column($vis, superclass($col), $handle);
  call_next_method();
  defined $col->{accuracy} or $col->{accuracy} = 5;
};

multimethod visit_column =>
  qw(DBO::Visitor::Initialize DBO::Column::Option DBO::Handle) =>
sub {
  my ($vis, $col, $handle) = @_;
  # visit_column($vis, superclass($col), $handle);
  call_next_method();
  defined $col->{values} or die DBO::Exception->new
    (NO_OPTION_VALUES => "No values property for option column.");
  ref $col->{values} eq 'ARRAY' or die DBO::Exception->new
    (OPTION_VALUES_TYPE => "values property is a %s, (should be ARRAY).",
     ref $col->{values});
};

multimethod visit_column =>
  qw(DBO::Visitor::Initialize DBO::Column::ForeignKey DBO::Handle) =>
sub {
  my ($vis, $col, $handle) = @_;
  # visit_column($vis, superclass($col), $handle);
  call_next_method();
  $col->{foreign_table} or die "No foreign_table option for $col->{name}.";
  $col->{foreign_col} or die "No foreign_col option for $col->{name}.";
};

1;
