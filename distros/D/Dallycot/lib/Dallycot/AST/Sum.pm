package Dallycot::AST::Sum;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Calculates the sum of a list of values

use strict;
use warnings;

use utf8;
use parent 'Dallycot::AST';

use Carp qw(croak);
use List::MoreUtils qw(all_u);

use Readonly;

Readonly my $NUMERIC => ['Numeric'];

sub to_string {
  my ($self) = @_;

  return "(" . join( "+", map { $_->to_string } @{$self} ) . ")";
}

sub to_rdf {
  my($self, $model) = @_;

  #
  # node -> expression_set -> [ ... ]
  #
  return $model -> apply(
    $model -> meta_uri('loc:sum'),
    [ @$self ],
    {}
  );
  # my $bnode = $model->bnode;
  # $model -> add_type($bnode, 'loc:Sum');
  #
  # foreach my $expr (@$self) {
  #   $model -> add_expression($bnode, $expr);
  # }
  # return $bnode;
}

sub execute {
  my ( $self, $engine ) = @_;

  return $engine->collect( map { [ $_, $NUMERIC ] } @$self )->then(
    sub {
      my $num_durations = grep { $_ -> isa('Dallycot::Value::Duration') } @_;
      my $num_dates = grep { $_ -> isa('Dallycot::Value::DateTime') } @_;
      if( $num_durations == @_ ) {
        my (@values) = map { $_ -> value } @_;
        my $first = pop @values;
        my $next = pop @values;
        my $acc = $first + $next;
        $acc += $_ for @values;
        return Dallycot::Value::Duration->new( object => $acc );
      }
      elsif( $num_durations + $num_dates == @_ && $num_dates == 1 ) {
        my (@values) = map { $_ -> value } @_;
        my $first = shift @values;
        my $next = shift @values;
        my $acc = $first + $next;
        $acc += $_ for @values;
        return Dallycot::Value::DateTime->new( object => $acc );
      }
      elsif( $num_dates > 1 ) {
        croak 'Multiple dates can not be added together';
      }
      else {
        my (@values) = map { $_->value } @_;

        my $acc = pop @values;
        my $next = pop @values;
        $acc = $acc + $next;

        $acc += $_ for @values;

        return Dallycot::Value::Numeric->new($acc);
      }
    }
  );
}

1;
