package Dallycot::Value::TripleStore;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Manages a memory-based triple store of linked data

use strict;
use warnings;

use utf8;
use parent 'Dallycot::Value::Any';

use experimental qw(switch);

use Promises qw(deferred);

sub as_text {
  my ($self) = @_;

  my $base_url = $self->[0];
  my $subject  = $self->[1];
  my $size     = $self->[2]->size();

  return "Graph($subject in $base_url with $size triples)";
}

sub to_rdf {
  my( $self, $model ) = @_;

  return RDF::Trine::Node::Resource->new($self->[1]->as_string);
}

sub is_defined { return 1 }

sub is_empty {
  my ($self) = @_;

  return 0 == $self->[2]->count_statements( $self->[1], undef, undef );
}

sub calculate_length {
  my ( $self, $engine ) = @_;

  return Dallycot::Value::Numeric->new( $self->[2]->size() );
}

sub id {
  my ($self) = @_;

  return "<" . $self->[1]->as_string .">";
}

sub type {
  my ($self) = @_;

  my @types = map { $_->[1] } $self->_fetch_property('http://www.w3.org/1999/02/22-rdf-syntax-ns#type');
  return Dallycot::Value::Set->new(@types);
}

sub _fetch_property {
  my ( $self, $prop ) = @_;

  my ( $base, $subject, $graph ) = @$self;

  my $pred_node = RDF::Trine::Node::Resource->new($prop);
  my @nodes = $graph->objects( $subject, $pred_node );

  my @results;

  for my $node (@nodes) {
    if ( $node->is_resource ) {
      push @results, bless [ $base, $node, $graph ] => __PACKAGE__;
    }
    elsif ( $node->is_literal ) {
      my $datatype = "String";
      given ($datatype) {
        when ("String") {
          if ( $node->has_language ) {
            push @results,
              Dallycot::Value::String->new( $node->literal_value, $node->literal_value_language );
          }
          else {
            push @results, Dallycot::Value::String->new( $node->literal_value );
          }
        }
        when ("Numeric") {
          push @results, Dallycot::Value::Numeric->new( $node->literal_value );
        }
      }
    }
  }

  return @results;
}

sub fetch_property {
  my ( $self, $engine, $prop ) = @_;

  my $d = deferred;

  my $worked = eval {
    $d->resolve( $self->_fetch_property($prop) );

    1;
  };

  if ($@) {
    $d->reject($@);
  }
  elsif ( !$worked ) {
    $d->reject("Unable to fetch $prop.");
  }

  return $d->promise;
}

1;
