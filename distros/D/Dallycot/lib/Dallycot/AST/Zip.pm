package Dallycot::AST::Zip;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Combines a set of collections into a collection of vectors

use strict;
use warnings;

use utf8;
use parent 'Dallycot::AST';

use Promises qw(collect deferred);

use List::Util qw(max);
use List::MoreUtils qw(all any each_array);

sub to_string {
  my ($self) = @_;
  return '(' . join( ' Z ', map { $_->to_string } @{$self} ) . ')';
}

sub to_rdf {
  my($self, $model) = @_;

  return $model -> apply(
    $model -> meta_uri('loc:zip'),
    [ @$self ],
    {}
  );
  # my $bnode = $model->bnode;
  # $model -> add_type($bnode, 'loc:Zip');
  #
  # $model -> add_list($bnode, 'loc:expressions',
  #   map { $_ -> to_rdf($model) } @$self
  # );
  # return $bnode;
}

sub execute {
  my ( $self, $engine ) = @_;

  # produce a vector with the head of each thing
  # then a tail promise for the rest
  # unless we're all vectors, in which case zip everything up now!
  if ( any { $_->isa('Dallycot::AST') } @$self ) {
    return $engine->collect(@$self)->then(
      sub {
        my $newself = bless \@_ => __PACKAGE__;
        $newself->execute($engine);
      }
    );
  }
  elsif ( all { $_->isa('Dallycot::Value::Vector') } @$self ) {

    # all vectors
    my $it = each_arrayref(@$self);
    my @results;
    while ( my @vals = $it->() ) {
      push @results, bless \@vals => 'Dallycot::Value::Vector';
    }

    my $d = deferred;

    $d->resolve( bless \@results => 'Dallycot::Value::Vector' );

    return $d->promise;
  }
  elsif ( all { $_->isa('Dallycot::Value::String') } @$self ) {

    # all strings
    my @sources = map { \{ $_->value } } @$self;
    my $length = max( map { length $$_ } @sources );
    my @results;
    for ( my $idx = 0; $idx < $length; $idx++ ) {
      my $s = join( "", map { substr( $$_, $idx, 1 ) } @sources );
      push @results, Dallycot::Value::String->new($s);
    }
    my $d = deferred;

    $d->resolve( bless \@results => 'Dallycot::Value::Vector' );

    return $d->promise;
  }
  else {
    my $d = deferred;

    collect( map { $_->head($engine) } @$self )->done(
      sub {
        my (@heads) = map {@$_} @_;
        collect( map { $_->tail($engine) } @$self )->done(
          sub {
            my (@tails) = map {@$_} @_;
            my $r;
            $d->resolve(
              $r = bless [
                ( bless \@heads => 'Dallycot::Value::Vector' ),

                undef,

                Dallycot::Value::Lambda->new(
                  expression             => ( bless \@tails => __PACKAGE__ ),
                  bindings               => [],
                  bindings_with_defaults => [],
                  options                => {}
                )
              ] => 'Dallycot::Value::Stream'
            );
          },
          sub {
            $d->reject(@_);
          }
        );
      },
      sub {
        $d->reject(@_);
      }
    );

    return $d->promise;
  }
}

1;
