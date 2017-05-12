#------------------------------------------------------------------------------
# DBO::Visitor::Check - check record for validity
#
# DESCRIPTION
#   A visitor class that checks a record from a database table
#   (represented as a hash mapping column name to value) for validity.
#
# AUTHOR
#   Gareth Rees
#
# COPYRIGHT
#   Copyright (c) 1999 Canon Research Centre Europe Ltd/
#
# $Id: Check.pm,v 1.3 1999/06/21 15:11:24 garethr Exp $
#------------------------------------------------------------------------------

use strict;
package DBO::Visitor::Check;
use base qw(DBO::Visitor);
use Class::Multimethods;

multimethod visit_table =>
  qw(DBO::Visitor::Check DBO::Table DBO::Handle) =>
sub {
  my ($vis, $table, $handle) = @_;
  foreach my $col (@{$table->{columns}}) {
    visit_column($vis, $col, $handle) or return 0;
  }
  return 1;
};

multimethod visit_column =>
  qw(DBO::Visitor::Check DBO::Column::Base DBO::Handle) =>
sub {
  my ($vis, $col, $handle) = @_;
  if ($col->{not_null} and not defined $vis->{record}{$col->{name}}) {
    $vis->{error} = DBO::Exception->new
      (NULL_COLUMN => "You must supply a value for %s.", $col->{name});
    return 0;
  }
  return 1;
};

multimethod visit_column =>
  qw(DBO::Visitor::Check DBO::Column::Number DBO::Handle) =>
sub {
  my ($vis, $col, $handle) = @_;
  # visit_column($vis, superclass($col), $handle) or return 0;
  call_next_method() or return 0;
  my $value = $vis->{record}{$col->{name}};
  if (defined $value and do { local $^W; $value + 0 ne $value }) {
    $vis->{error} = DBO::Exception->new
      (NUMERIC => "You must supply a number for %s.", $col->{name});
    return 0;
  }
  return 1;
};

multimethod visit_column =>
  qw(DBO::Visitor::Check DBO::Column::Integer DBO::Handle) =>
sub {
  my ($vis, $col, $handle) = @_;
  # visit_column($vis, superclass($col), $handle) or return 0;
  call_next_method() or return 0;
  my $value = $vis->{record}{$col->{name}};
  if (defined $value and $value != int $value) {
    $vis->{error} = DBO::Exception->new
      (INTEGER => "You must supply an integer for %s.", $col->{name});
    return 0;
  }
  return 1;
};

multimethod visit_column =>
  qw(DBO::Visitor::Check DBO::Column::Unsigned DBO::Handle) =>
sub {
  my ($vis, $col, $handle) = @_;
  # visit_column($vis, superclass($col), $handle) or return 0;
  call_next_method() or return 0;
  my $value = $vis->{record}{$col->{name}};
  if (defined $value and $value < 0) {
    $vis->{error} = DBO::Exception->new
      (UNSIGNED => "The value for %s must be non-negative.", $col->{name});
    return 0;
  }
  return 1;
};

multimethod visit_column =>
  qw(DBO::Visitor::Check DBO::Column::Option DBO::Handle) =>
sub {
  my ($vis, $col, $handle) = @_;
  # visit_column($vis, superclass($col), $handle) or return 0;
  call_next_method() or return 0;
  my $value = $vis->{record}{$col->{name}};
  unless (grep { $_ eq $value } @{$col->{values}}) {
    $vis->{error} = DBO::Exception->new
      (OPTION => "The value for %s must be one of %s.",
       $col->{name}, join ", ", @{$col->{values}});
    return 0;
  }
  return 1;
};

multimethod visit_column =>
  qw(DBO::Visitor::Check DBO::Column::ForeignKey DBO::Handle) =>
sub {
  my ($vis, $col, $handle) = @_;
  # visit_column($vis, superclass($col), $handle) or return 0;
  call_next_method() or return 0;
  my $value = $vis->{record}{$col->{name}};

  # TODO: Fetch values from foreign table and check.

  return 1;
};

multimethod visit_column =>
  qw(DBO::Visitor::Check DBO::Column::Char DBO::Handle) =>
sub {
  my ($vis, $col, $handle) = @_;
  # visit_column($vis, superclass($col), $handle) or return 0;
  call_next_method() or return 0;
  my $value = $vis->{record}{$col->{name}};
  if (defined $value and $col->{max_length} < length $value) {
    $vis->{error} = DBO::Exception->new
      (LENGTH => "The value for %s is %d characters long (must be at most %d characters long).",
       $col->{name}, length $value, $col->{max_length});
    return 0;
  }
  return 1;
};

multimethod visit_column =>
  qw(DBO::Visitor::Check DBO::Column::Time DBO::Handle) =>
sub {
  my ($vis, $col, $handle) = @_;
  # visit_column($vis, superclass($col), $handle) or return 0;
  call_next_method() or return 0;
  my $value = $vis->{record}{$col->{name}};
  if ($value !~ /^\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d/) {
    $vis->{error} = DBO::Exception->new
      (TIME => "The value for %s must look like '1999-05-15 23:46:00'.",
       $col->{name}, $value);
    return 0;
  }
  return 1;
};

1;
