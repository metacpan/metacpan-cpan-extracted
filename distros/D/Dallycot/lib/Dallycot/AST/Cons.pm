package Dallycot::AST::Cons;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Compose lambdas into a new lambda

use strict;
use warnings;

use utf8;
use parent 'Dallycot::AST';

use Promises qw(deferred);

sub to_rdf {
  my($self, $model) = @_;

  return $model -> apply(
    $model -> meta_uri('loc:consolidate'),
    [ @$self ],
    {}
  );
}

sub execute {
  my ( $self, $engine ) = @_;

  return $engine->collect(@$self)->then(
    sub {
      my ( $root, @things ) = @_;
      $root->prepend(@things);
    }
  );
}

1;
