#------------------------------------------------------------------------------
# DBO::Visitor::CheckKeys - check key fields for validity
#
# DESCRIPTION
#   A visitor class that checks the key fields of a record (represented
#   as a hash mapping column name to value) for validity.
#
# AUTHOR
#   Gareth Rees
#
# COPYRIGHT
#   Copyright (c) 1999 Canon Research Centre Europe Ltd/
#
# $Id: CheckKeys.pm,v 1.1 1999/06/14 17:05:21 garethr Exp $
#------------------------------------------------------------------------------

use strict;
package DBO::Visitor::CheckKeys;
use base qw(DBO::Visitor::Check);
use Class::Multimethods;

multimethod visit_table =>
  qw(DBO::Visitor::CheckKeys DBO::Table DBO::Handle) =>
sub {
  my ($vis, $table, $handle) = @_;
  foreach my $col (@{$table->{keys}}) {
    visit_column($vis, $col, $handle) or return 0;
  }
  return 1;
};

1;
