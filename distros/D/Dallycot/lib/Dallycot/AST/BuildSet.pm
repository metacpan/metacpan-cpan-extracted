package Dallycot::AST::BuildSet;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Create set value

use strict;
use warnings;

use utf8;
use parent 'Dallycot::AST';

sub to_rdf {
  my ( $self, $model ) = @_;

  return $model -> apply(
    $model -> meta_uri('loc:build-set'),
    [ @$self ],
    {}
  );
  # my $bnode = $model -> bnode;
  # $model -> add_type($bnode, 'loc:Set');
  # $model -> add_list($bnode, 'loc:expressions',
  #   map { $_ -> to_rdf($model) } @{$self}
  # );
  #
  # return $bnode;
}

sub execute {
  my ( $self, $engine ) = @_;

  return $engine->collect(@$self)->then(
    sub {
      return Dallycot::Value::Set->new(@_);
    }
  );
}

1;
