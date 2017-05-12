package Dallycot::Library::LOC;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Core library of useful functions

use strict;
use warnings;

use utf8;

use Dallycot::Library;

use Promises qw(deferred);
use List::Util qw(all any);
use Carp qw(croak);
use experimental qw(switch);

ns 'http://www.dallycot.net/ns/loc/1.0#';

define 'all-true' => (
  hold => 1,
  arity => [0],
  options => {},
), sub {
  my ( $engine, $options, @things ) = @_;

  return $engine->TRUE unless @things;

  my $d = deferred;

  my $process_loop;

  $process_loop = sub {
    if ( !@things ) {
      $d->resolve( $engine->TRUE );
    }
    else {
      $engine->execute( shift @things, ['Boolean'] )->done(
        sub {
          if ( $_[0]->value ) {
            $process_loop->();
          }
          else {
            $d->resolve( $engine->FALSE );
          }
        },
        sub {
          $d->reject(@_);
        }
      );
    };

    return;
  };

  $process_loop->();

  return $d -> promise;
};

define 'any-true' => (
  hold => 1,
  arity => [0],
  options => {},
), sub {
  my ( $engine, $options, @things ) = @_;

  return $engine->FALSE unless @things;

  my $d = deferred;

  my $process_loop;

  $process_loop = sub {
    if ( !@things ) {
      $d->resolve( $engine->TRUE );
    }
    else {
      $engine->execute( shift @things, ['Boolean'] )->done(
        sub {
          if ( $_[0]->value ) {
            $d -> resolve( $engine->TRUE );
          }
          else {
            $process_loop -> ();
          }
        },
        sub {
          $d->reject(@_);
        }
      );
    }

    return;
  };

  $process_loop->();

  return $d -> promise;
};

define 'y-combinator' => '(function) :> function(function, ___)';

define foldl => <<'EOD';
(
  folder := y-combinator(
    (self, pad, function, stream) :> (
      (?stream) : (
        next := function(pad, stream');
        [ next, self(self, next, function, stream...) ]
      )
      ( ) : [ ]
    )
  );
  (initial, function, stream) :> (
    (?stream) : folder(initial, function, stream)
    (       ) : [ initial ]
  )
)
EOD

define foldl1 => <<'EOD';
  (function, stream) :> (
    (?stream) : foldl(stream', function, stream...)
    (       ) : [ ]
  )
EOD

define map => <<'EOD';
y-combinator(
  (self, mapper, stream) :> (
    (?stream) : [ mapper(stream'), self(self, mapper, stream...) ]
    (       ) : [ ]
  )
)
EOD

define filter => <<'EOD';
y-combinator(
  (self, selector, stream) :> (
    (?stream) : (
      (selector(stream')) : [ stream', self(self, selector, stream...) ]
      (                 ) : self(self, selector, stream...)
    )
    (       ) : [ ]
  )
)
EOD

define 'build-filter' => (
  hold => 0,
  arity => [0],
  options => {},
), sub {
  my ( $engine, $options, @functions ) = @_;

  my $stream = pop @functions;
  return collect( map { maybe_promise( $_->is_lambda ) } @functions )->then(
    sub {
      my @flags = map {@$_} @_;
      if ( any { !$_ } @flags ) {
        croak "All but the last term in a filter must be lambdas.";
      }
    }
  )->then(
    sub {
      return collect( map { maybe_promise( $_->min_arity ) } @functions )->then(
        sub {
          my (@arities) = map {@$_} @_;
          if ( any { 1 != $_ } @arities ) {
            croak "All lambdas in a filter must have arity 1.";
          }
        }
      );
    }
  )->then(
    sub {
      return maybe_promise( $stream->is_lambda )->then(
        sub {
          my ($flag) = @_;
          if ($flag) {
            return $engine->make_filter( $engine->compose_filters( @functions, $stream ) );
          }
          else {
            return $stream->apply_filter( $engine, $engine->compose_filters(@functions) );
          }
        }
      );
    }
  );
};

define 'build-list' => (
  hold => 1,
  arity => [0],
  options => {},
), sub {
  my ( $engine, $options, @expressions ) = @_;

  given ( scalar(@expressions) ) {
    when (0) {
      return Dallycot::Value::EmptyStream->new;
    }
    when (1) {
      return $engine->execute( $expressions[0] )->then(
        sub {
          my ($result) = @_;
          Dallycot::Value::Stream->new($result);
        }
      );
    }
    default {
      my $last_expr = pop @expressions;
      my $promise;
      if ( $last_expr->isa('Dallycot::Value') ) {
        push @expressions, $last_expr;
      }
      else {
        $promise = $engine->make_lambda($last_expr);
      }
      return $engine->collect(@expressions)->then(
        sub {
          my (@items) = @_;
          my $result = Dallycot::Value::Stream->new( ( pop @items ), undef, $promise );
          while (@items) {
            $result = Dallycot::Value::Stream->new( ( pop @items ), $result );
          }
          $result;
        }
      );
    }
  }
};

define 'build-map' => (
  hold => 0,
  arity => [0],
  options => {}
), sub {
  my ( $engine, $options, @functions ) = @_;
  my $stream = pop @functions;
  return collect( map { maybe_promise( $_->is_lambda ) } @functions )->then(
    sub {
      my @flags = map {@$_} @_;
      if ( any { !$_ } @flags ) {
        croak "All but the last term in a mapping must be lambdas.";
      }
    }
  )->then(
    sub {
      return collect( map { maybe_promise( $_->min_arity ) } @functions )->then(
        sub {
          my (@arities) = map {@$_} @_;
          if ( any { 1 != $_ } @arities ) {
            croak "All lambdas in a mapping must have arity 1.";
          }
        }
      );
    }
  )->then(
    sub {
      return maybe_promise( $stream->is_lambda )->then(
        sub {
          my ($flag) = @_;

          if ($flag) {
            return $engine->make_map( $engine->compose_lambdas( @functions, $stream ) );
          }
          else {
            my $transform = $engine->compose_lambdas(@functions);

            return $stream->apply_map( $engine, $transform );
          }
        }
      );
    }
  );
};

define upfrom => <<'EOD';
y-combinator( (self, n) :> [ n, self(self, n + 1) ] )
EOD

define range => <<'EOD';
y-combinator(
  (self, m, n) :> (
    (m > n) : [ m, self(self, m - 1, n) ]
    (m = n) : [ m ]
    (m < n) : [ m, self(self, m + 1, n) ]
    (     ) : [ ]
  )
)
EOD

define 'build-set' => (
  hold => 0,
  arity => [0],
  options => {}
), sub {
  my( $engine, $options, @things ) = @_;

  return Dallycot::Value::Set->new(@things);
};

define 'build-vector' => (
  hold => 0,
  arity => [0],
  options => {}
), sub {
  my( $engine, $options, @things ) = @_;

  return Dallycot::Value::Vector->new(@things);
};

define 'compose-functions' => (
  hold => 0,
  arity => [0],
  options => {}
), sub {
  my ( $engine, $options, @functions ) = @_;

  return collect( map { maybe_promise( $_->is_lambda ) } @functions )->then(
    sub {
      my @flags = map {@$_} @_;
      if ( any { !$_ } @flags ) {
        croak "All terms in a function composition must be lambdas";
      }
    }
  )->then(
    sub {
      return collect( map { maybe_promise( $_->min_arity ) } @functions )->then(
        sub {
          my (@arities) = map {@$_} @_;

          if ( any { 1 != $_ } @arities ) {
            croak "All lambdas in a function composition must have arity 1";
          }
        }
      );
    }
  )->then(
    sub {
      return $engine->compose_lambdas(@functions);
    }
  );
};

define consolidate => (
  hold => 0,
  arity => [1],
  options => {},
), sub {
  my( $engine, $options, $root, @things) = @_;

  return $root unless @things;

  return $root->prepend(@things);
};

sub compare (&$@) {
  my ( $comparator, $engine, @expressions ) = @_;

  my $d = deferred;

  my $process_loop;

  $process_loop = sub {
    my( $left_value ) = @_;

    if ( !@expressions ) {
      $d -> resolve( $engine -> TRUE );
    }
    else {
      $engine -> execute( shift @expressions ) -> then(
        sub {
          my ($right_value) = @_;
          $engine->coerce( $left_value, $right_value, [ $left_value->type, $right_value->type ] )->done(
            sub {
              my ( $cleft, $cright ) = @_;
              $comparator->( $cleft, $cright )->done(
                sub {
                  if ( $_[0] ) {
                    $process_loop->( $right_value, @expressions );
                  }
                  else {
                    $d->resolve( $engine->FALSE );
                  }
                },
                sub {
                  $d->reject(@_);
                }
              );
            },
            sub {
              $d -> reject(@_);
            }
          );
        },
        sub {
          $d -> reject(@_);
        }
      );
    }
  };

  $engine->execute( shift @expressions )->done(
    sub {
      $process_loop->( $_[0] );
    },
    sub {
      $d->reject(@_);
    }
  );

  return $d->promise;
}

define 'all-decreasing' => (
  hold => 1,
  arity => [1],
  options => {}
), sub {
  my ( $engine, $options, @things ) = @_;

  compare {
    my($a, $b) = @_;
    $a -> is_greater_or_equal( $engine, $b );
  } @things;
};

define 'all-increasing' => (
  hold => 1,
  arity => [1],
  options => {}
), sub {
  my ( $engine, $options, @things ) = @_;

  compare {
    my($a, $b) = @_;
    $a -> is_less_or_equal( $engine, $b );
  } @things;
};

define 'all-strictly-decreasing'  => (
  hold => 1,
  arity => [1],
  options => {}
), sub {
  my ( $engine, $options, @things ) = @_;

  compare {
    my($a, $b) = @_;
    $a -> is_greater( $engine, $b );
  } @things;
};

define 'all-strictly-increasing'  => (
  hold => 1,
  arity => [1],
  options => {}
), sub {
  my ( $engine, $options, @things ) = @_;

  compare {
    my($a, $b) = @_;
    $a -> is_less( $engine, $b );
  } @things;
};

define 'all-equal'  => (
  hold => 1,
  arity => [1],
  options => {}
), sub {
  my ( $engine, $options, @things ) = @_;

  compare {
    my($a, $b) = @_;
    $a -> is_equal( $engine, $b );
  } @things;
};

define 'all-unique' => (
  hold => 0,
  arity => [1],
  options => {}
), sub {
  my( $engine, $options, @values ) = @_;

  my @types = map { $_->type } @values;
  return $engine->coerce( @values, \@types )->then(
    sub {
      my (@new_values) = @_;

      # now make sure values are all different
      my %seen;
      if(all { !$seen{ $_->id }++ } @new_values) {
        return $engine->TRUE;
      }
      else {
        return $engine->FALSE;
      }
    }
  );
};

define 'not-empty' => (
  hold => 0,
  arity => 1,
  options => {}
), sub {
  my( $engine, $options, $result ) = @_;

  if ( blessed $result ) {
    return ( $result->is_defined && !$result->is_empty ? $engine->TRUE : $engine->FALSE );
  }
  else {
    return ( $engine->FALSE );
  }
};

define 'execute-list' => <<'EOD';
(sequence) :> (
  last(
    foldl(
      (),
      { (#2)() }/2,
      sequence
    )
  )
)
EOD

define 'invert' => (
  hold => 0,
  arity => 1,
  options => {}
), sub {
  my($engine, $options, $res) = @_;

  if ( $res->isa('Dallycot::Value::Boolean') ) {
    return Dallycot::Value::Boolean->new( !$res->value );
  }
  elsif ( $res->isa('Dallycot::Value::Lambda') ) {
    return $res -> invert;
    # return Dallycot::Value::Lambda->new(
    #   expression             => Dallycot::AST::Invert->new( $res->[0] ),
    #   bindings               => $res->[1],
    #   bindings_with_defaults => $res->[2],
    #   options                => $res->[3],
    #   closure_environment    => $res->[4],
    #   closure_namespaces     => $res->[5]
    # );
  }
  else {
    return Dallycot::Value::Boolean->new( !$res->is_defined );
  }
};

1;
