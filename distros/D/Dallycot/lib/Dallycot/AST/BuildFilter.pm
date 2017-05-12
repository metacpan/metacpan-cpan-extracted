package Dallycot::AST::BuildFilter;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Create lambda or filtered stream

use strict;
use warnings;

use utf8;
use parent 'Dallycot::AST';

use Carp qw(croak);
use Dallycot::Util qw(maybe_promise);

use List::Util     qw(all any);
use Promises       qw(deferred collect);

sub to_rdf {
  my($self, $model) = @_;

  return $model -> apply(
    $model -> meta_uri('loc:build-filter'),
    [ @$self ],
    {}
  );

  # my $bnode = $model -> bnode;
  # $model -> add_type($bnode, 'loc:Filter');
  # $model -> add_list($bnode, 'loc:expressions',
  #   map { $_ -> to_rdf($model) } @{$self}
  # );
  #
  # return $bnode;
}

sub execute {
  my ( $self, $engine ) = @_;

  my $d = deferred;

  return $engine->collect(@$self)->then(
    sub {
      my (@functions) = @_;
      my $stream = pop @functions;
      return collect( map { maybe_promise( $_->is_lambda ) } @functions )->then(
        sub {
          my @flags = map {@$_} @_;
          if ( any { !$_ } @flags ) {
            croak "All but the last term in a filter must be lambdas.";
          }
          return ( \@functions, $stream );
        }
      );
    }
    )->then(
    sub {
      my ( $functions, $stream ) = @_;

      return collect( map { maybe_promise( $_->min_arity ) } @$functions )->then(
        sub {
          my (@arities) = map {@$_} @_;
          if ( any { 1 != $_ } @arities ) {
            croak "All lambdas in a filter must have arity 1.";
          }
          return ( $functions, $stream );
        }
      );
    }
    )->then(
    sub {
      my ( $functions, $stream ) = @_;

      return maybe_promise( $stream->is_lambda )->then(
        sub {
          my ($flag) = @_;
          if ($flag) {
            return $engine->make_filter( $engine->compose_filters( @$functions, $stream ) );
          }
          else {
            return $stream->apply_filter( $engine, $engine->compose_filters(@$functions) );
          }
        }
      );
    }
    );
}

1;
