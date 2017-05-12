package Dallycot::AST::BuildVector;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Create vector value

use strict;
use warnings;

use utf8;
use parent 'Dallycot::AST';

sub to_rdf {
  my($self, $model) = @_;

  return $model -> apply(
    $model -> meta_uri('loc:build-vector'),
    [ @$self ],
    {}
  );
  # my $bnode = $model -> bnode;
  # $model -> add_type($bnode, 'loc:Vector');
  # $model -> add_list($bnode, 'loc:expressions',
  #   map { $_ -> to_rdf($model) } @$self
  # );
}

sub execute {
  my ( $self, $engine ) = @_;

  return $engine->collect(@$self)->then(
    sub {
      my (@bits) = @_;

      bless \@bits => 'Dallycot::Value::Vector';
    }
  );
}

1;
