package Dallycot::AST::BuildRange;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Create open or closed range

use strict;
use warnings;

use utf8;
use parent 'Dallycot::AST';

sub to_rdf {
  my($self, $model) = @_;

  if(@$self > 1) {
    return $model -> apply(
      $model -> meta_uri('loc:range'),
      [
        $self->[0], $self -> [1]
      ]
    );
  }
  else {
    return $model -> apply(
      $model -> meta_uri('loc:upfrom'),
      [ $self -> [0] ]
    );
  }
  # my $bnode = $model -> bnode;
  # $model -> add_type($bnode, 'loc:Range');
  # $model -> add_first($bnode, $self->[0]);
  # if(@$self > 1) {
  #   $model -> add_last($bnode, $self->[1]);
  # }
  # return $bnode;
}

sub execute {
  my ( $self, $engine ) = @_;

  if ( @$self == 1 || !defined( $self->[1] ) ) {    # semi-open range
    return $engine->execute( $self->[0] )->then(
      sub {
        bless [@_] => 'Dallycot::Value::OpenRange';
      }
    );
  }
  else {
    return $engine->collect(@$self)->then(
      sub {
        my ( $left_value, $right_value ) = @_;

        $left_value->is_less( $engine, $right_value )->then(
          sub {
            my ($f) = @_;

            bless [ $left_value, $right_value, $f ? 1 : -1 ] => 'Dallycot::Value::ClosedRange';
          }
        );
      }
    );
  }
}

1;
