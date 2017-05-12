package Dallycot::Resolver;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Resolve URLs into data objects

use strict;
use warnings;

use utf8;
use MooseX::Singleton;

use namespace::autoclean;

use CHI;
use Promises qw(deferred);
use RDF::Trine::Parser;
use Mojo::UserAgent;

use Dallycot::Resolver::Request;

has cache => (
  is      => 'ro',
  default => sub {
    CHI->new( driver => 'Memory', cache_size => '32M', datastore => {} );
  }
);

has ua => (
  is      => 'ro',
  default => sub {
    my $ua = Mojo::UserAgent->new;
    $ua->connect_timeout(30);
    return $ua;
  }
);

sub get {
  my ( $self, $url ) = @_;


  my $data = $self->cache->get($url);
  if ( defined($data) ) {
    my $deferred = deferred;
    $deferred->resolve($data);
    return $deferred->promise;
  }
  else {
    print STDERR "Getting $url\n";
    my $request = Dallycot::Resolver::Request->new(
      ua            => $self->ua,
      url           => $url,
      canonical_url => $url,
    );
    return $request->run->then(
      sub {
        ($data) = @_;
        $self->cache->set( $url, $data );
        $data;
      }
    );
  }
}

__PACKAGE__->meta->make_immutable;

1;

__END__
=encoding utf8

=head1 SYNOPSIS

my $resolver = Dallycot::Resolver->new(
  cache => CHI->new(...)
);

my $promise = $resolver->get($uri);

=head1 DESCRIPTION

The resolver will fetch the linked data at the provided URL and
return a promise that will be fulfilled with the parsed/extracted
RDF as a simple graph. Different backends will parse data from
different sources.

In order of preference:
- JSON-LD
- RDF/XML
- RDFa
