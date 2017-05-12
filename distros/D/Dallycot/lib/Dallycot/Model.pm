package Dallycot::Model;
our $AUTHORITY = 'cpan:JSMITH';

use Moose;

use RDF::Trine;
use RDF::Trine::Serializer::TSV;

has model => (
  is => 'ro',
  isa => 'RDF::Trine::Model',
  default => sub {
    RDF::Trine::Model -> new
  },
  lazy => 1,
  handles => [qw/
    add_statement
    add_list
    objects
  /]
);

has _prefixes => (
  isa => 'RDF::Trine::NamespaceMap',
  is => 'ro',
  default => sub {
    RDF::Trine::NamespaceMap->new({
      'loc' => 'http://www.dallycot.net/ns/loc/1.0#',
      'rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
      'rdfs' => 'http://www.w3.org/2000/01/rdf-schema#',
      'xsd' => 'http://www.w3.org/2001/XMLSchema#',
    })
  },
  handles => {qw/
    expand_uri uri
  /}
);

sub run {
  my($self, $uri) = @_;

  my $loc = 'http://www.dallycot.net/ns/loc/1.0#';
  my $loc_length = length($loc);

  if(!blessed($uri)) {
    $uri = RDF::Trine::Node::Resource->new($uri);
  }

  my @types = map {
    substr($_, $loc_length)
  } grep {
    substr($_, 0, $loc_length) eq $loc
  } $self -> _types($uri);

  if(@types > 1) {
    croak $uri->value . " is not a unique linked open code type";
  }
  elsif(@types == 1) {
    my $method = $self -> can("run_".$types[0]);

    if(!$method) {
      croak(($uri->value // '(nil)') . " is not a valid linked open code type");
    }

    return $self -> $method($uri);
  }
  else {
    # it is probably a value - so we build out a Perl object to represent it

  }
}

sub run_Application {
  my($self, $uri) = @_;


}

sub run_Sequence {
  my($self, $uri) = @_;

  # $uri points to a linked list, but also has a set of assignments that
  # need to be calculated

}

sub run_GuardedSequence {
  my($self, $uri) = @_;

}

sub _types {
  my($self, $uri) = @_;

  map {
    $_ -> uri_value
  } $self -> model -> objects(
    $uri,
    $self -> expand_uri('rdf:type'),
    undef,
    type => 'node'
  );
}

sub as_turtle {
  my($self) = @_;

  my $serializer = RDF::Trine::Serializer::Turtle -> new(
    namespaces => RDF::Trine::NamespaceMap->new({
      'loc' => 'http://www.dallycot.net/ns/loc/1.0#',
      'rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
      'rdfs' => 'http://www.w3.org/2000/01/rdf-schema#',
      'xsd' => 'http://www.w3.org/2001/XMLSchema#',
    })
  );
  return $serializer -> serialize_model_to_string($self -> model);
}

sub as_ntriples {
  my($self) = @_;

  my $serializer = RDF::Trine::Serializer::NTriples::Canonical -> new(
  );
  return $serializer -> serialize_model_to_string($self -> model);
}

sub as_tsv {
  my($self) = @_;

  my $serializer = RDF::Trine::Serializer::TSV -> new(
    namespaces => RDF::Trine::NamespaceMap->new({
      'loc' => 'http://www.dallycot.net/ns/loc/1.0#',
      'rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
      'rdfs' => 'http://www.w3.org/2000/01/rdf-schema#',
      'xsd' => 'http://www.w3.org/2001/XMLSchema#',
    })
  );
  return $serializer -> serialize_model_to_string($self -> model);
}

sub as_xml {
  my($self) = @_;

  my $serializer = RDF::Trine::Serializer::RDFXML -> new(
    namespaces => RDF::Trine::NamespaceMap->new({
      'loc' => 'http://www.dallycot.net/ns/loc/1.0#',
      'rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
      'rdfs' => 'http://www.w3.org/2000/01/rdf-schema#',
      'xsd' => 'http://www.w3.org/2001/XMLSchema#',
    })
  );
  return $serializer -> serialize_model_to_string($self -> model);
}

sub as_dot {
  my($self) = @_;

  require RDF::Trine::Exporter::GraphViz;

  my $serializer = RDF::Trine::Exporter::GraphViz -> new(
    namespaces => {
      'loc' => 'http://www.dallycot.net/ns/loc/1.0#',
      'rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
      'rdfs' => 'http://www.w3.org/2000/01/rdf-schema#',
      'xsd' => 'http://www.w3.org/2001/XMLSchema#',
    },
    alias => sub {
      my($url) = @_;
      return 'nil' if $url eq 'http://www.w3.org/1999/02/22-rdf-syntax-ns#nil';
      return 'a' if $url eq 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type';
      return 'label' if $url eq 'http://www.w3.org/2000/01/rdf-schema#label';
      return 'head' if $url eq 'http://www.w3.org/1999/02/22-rdf-syntax-ns#first';
      return 'tail' if $url eq 'http://www.w3.org/1999/02/22-rdf-syntax-ns#rest';
      return 'value' if $url eq 'http://www.w3.org/1999/02/22-rdf-syntax-ns#value';
      undef;
    },
    root => $self->root->value
  );
  return $serializer -> to_string($self -> model);
}


1;
