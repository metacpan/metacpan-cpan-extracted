package Dallycot::AST::PropWalk;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Manages traversal of a graph

use strict;
use warnings;

use utf8;
use parent 'Dallycot::AST::LoopBase';

use Promises qw(collect deferred);

sub to_string {

}

sub execute {
  my ( $self, $engine ) = @_;

  my ( $root_expr, @steps ) = @$self;

  return $engine->execute($root_expr)->then(
    sub {
      my ($root) = [@_];

      if (@steps) {
        my $d = deferred;
        $self->process_loop( $engine, $d, root => $root, steps => \@steps );
        return $d;
      }
      elsif ( @$root > 1 ) {
        return bless $root => "Dallycot::Value::Set";
      }
      else {
        return @$root;
      }
    }
  );
}

sub process_loop {
  my ( $self, $engine, $d, %state ) = @_;

  my ( $root, $step, @steps ) = ( $state{root}, @{ $state{steps} || [] } );

  collect( map { $step->step( $engine, $_ ) } @$root )->done(
    sub {
      my (@results) = map {@$_} @_;
      if (@steps) {
        $self->process_loop( $engine, $d, root => \@results, steps => \@steps );
      }
      elsif ( @results > 1 ) {
        $d->resolve( bless \@results => "Dallycot::Value::Set" );
      }
      elsif ( @results == 1 ) {
        $d->resolve(@results);
      }
      else {
        $d->resolve( $engine->UNDEFINED );
      }
    },
    sub {
      $d->reject(@_);
    }
  );

  return;
}

1;
