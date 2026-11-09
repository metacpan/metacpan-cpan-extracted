package TestAge::FakeDbh;
# Stand-in for the database handle Age::Extension->inspect reads: answers the
# to_regclass probe and the ag_graph query from a plain description.

use strict;
use warnings;

# graphs => [ { name =>, namespace => } ], or undef for "no ag_catalog.ag_graph"
sub new { my ($class, %args) = @_; bless { calls => [], %args }, $class }

sub calls { @{ $_[0]{calls} } }

sub selectrow_array {
  my ($self, $sql) = @_;
  push @{ $self->{calls} }, $sql;
  return $self->{graphs} ? ('ag_catalog.ag_graph') : (undef);
}

sub selectall_arrayref {
  my ($self, $sql) = @_;
  push @{ $self->{calls} }, $sql;
  return [ map { { name => $_->{name}, namespace => $_->{namespace} } } @{ $self->{graphs} || [] } ];
}

1;
