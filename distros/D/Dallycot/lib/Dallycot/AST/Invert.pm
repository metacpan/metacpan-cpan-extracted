package Dallycot::AST::Invert;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Invert the truth of an expression or value

use strict;
use warnings;

use utf8;
use parent 'Dallycot::AST';

sub new {
  my ( $class, $expr ) = @_;

  $class = ref $class || $class;
  return bless [$expr] => $class;
}


sub to_rdf {
  my($self, $model) = @_;

  return $model -> apply(
    $model -> meta_uri('loc:invert'),
    [ $self->[0] ],
    {}
  );
}

sub execute {
  my ( $self, $engine ) = @_;

  return $engine->execute( $self->[0] )->then(
    sub {
      my ($res) = @_;

      if ( $res->isa('Dallycot::Value::Boolean') ) {
        return Dallycot::Value::Boolean->new( !$res->value );
      }
      elsif ( $res->isa('Dallycot::Value::Lambda') ) {
        return Dallycot::Value::Lambda->new(
          expression             => Dallycot::AST::Invert->new( $res->[0] ),
          bindings               => $res->[1],
          bindings_with_defaults => $res->[2],
          options                => $res->[3],
          closure_environment    => $res->[4],
          closure_namespaces     => $res->[5]
        );
      }
      else {
        return Dallycot::Value::Boolean->new( !$res->is_defined );
      }
    }
  );
}

1;
