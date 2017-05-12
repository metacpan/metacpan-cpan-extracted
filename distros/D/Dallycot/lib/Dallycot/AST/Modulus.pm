package Dallycot::AST::Modulus;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Calculate the modulus of a series of values

use strict;
use warnings;

use utf8;
use parent 'Dallycot::AST';

use Promises qw(deferred);

sub to_string {
  my $self = shift;
  return join( " mod ", map { $_->to_string } @$self );
}

sub to_rdf {
  my($self, $model) = @_;

  return $model -> apply(
    $model -> meta_uri('loc:modulus'),
    [ @$self ],
    {}
  );
  # my $bnode = $model->bnode;
  # $model -> add_type($bnode, 'loc:Modulus');
  #
  # $model -> add_list($bnode, 'loc:expressions',
  #   map { $_ -> to_rdf($model) } @$self
  # );
  # return $bnode;
}

sub execute {
  my ( $self, $engine ) = @_;

  my @expressions = @$self;
  return $engine->execute( ( shift @expressions ), ['Numeric'] )->then(
    sub {
      my ($left_value) = @_;

      my $d = deferred;

      $self->process_loop(
        $engine, $d,
        base        => $left_value,
        expressions => \@expressions
      );

      return $d;
    }
  );
}

sub process_loop {
  my ( $self, $engine, $d, %state ) = @_;
  my ( $left_value, $right_expr, @expressions )
    = ( $state{base}, @{ $state{expressions} || [] } );

  if ( !@expressions ) {
    $engine->execute( $right_expr, ['Numeric'] )->done(
      sub {
        my ($right_value) = @_;
        $d->resolve(
          Dallycot::Value::Numeric->new( $left_value->value->copy->bmod( $right_value->value ) ) );
      },
      sub {
        $d->reject(@_);
      }
    );
  }
  else {
    $engine->execute( $right_expr, ['Numeric'] )->done(
      sub {
        my ($right_value) = @_;
        $left_value = $left_value->copy->bmod( $right_value->value );
        if ( $left_value->is_zero ) {
          $d->resolve( Dallycot::Value::Numeric->new($left_value) );
        }
        else {
          $self->process_loop(
            $engine, $d,
            base        => $left_value,
            expressions => \@expressions
          );
        }
      },
      sub {
        $d->reject(@_);
      }
    );
  }

  return;
}

1;
