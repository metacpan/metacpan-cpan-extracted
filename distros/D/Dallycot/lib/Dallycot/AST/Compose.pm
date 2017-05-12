package Dallycot::AST::Compose;
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
    $model -> meta_uri('loc:compose'),
    [ @$self ],
    {}
  );
  # my $bnode = $model -> bnode;
  # $model -> add_type($bnode, 'loc:Composition');
  # $model -> add_list($bnode, 'loc:expressions',
  #   map { $_ -> to_rdf($model) } @{$self}
  # );
  #
  # return $bnode;
}

sub execute {
  my ( $self, $engine ) = @_;

  my $d = deferred;

  $engine->collect(@$self)->done(
    sub {
      my (@functions) = @_;
      if ( grep { !$_->isa('Dallycot::Value::Lambda') } @functions ) {
        $d->reject("All terms in a function composition must be lambdas");
      }
      elsif ( grep { 1 != $_->min_arity } @functions ) {
        $d->reject("All lambdas in a function composition must have arity 1");
      }
      else {
        $d->resolve( $engine->compose_lambdas(@functions) );
      }
    },
    sub {
      $d->reject(@_);
    }
  );

  return $d->promise;
}

1;
