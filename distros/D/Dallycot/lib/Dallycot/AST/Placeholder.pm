package Dallycot::AST::Placeholder;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: A no-op placeholder in function calls

use strict;
use warnings;

use utf8;
use parent 'Dallycot::AST';

sub to_string { return "_" }

sub to_rdf {
  my($self, $model) = @_;

  my $bnode = $model -> bnode;
  $model -> add_type($bnode, 'loc:Placeholder');
  return $bnode;
}

sub new {
  return bless [] => __PACKAGE__;
}

1;
