package Dallycot::TextResolver;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Resolve URLs into text objects

use strict;
use warnings;

use utf8;
use experimental qw(switch);

use MooseX::Singleton;

use namespace::autoclean;

use CHI;
use Promises qw(deferred);
use RDF::Trine::Parser;
use Mojo::UserAgent;

use Dallycot::TextResolver::Request;

has cache => (
  is      => 'ro',
  default => sub {
    CHI->new( driver => 'Memory', cache_size => '32M', datastore => {} );
  }
);

has ua => (
  is      => 'ro',
  default => sub {
    Mojo::UserAgent->new;
  }
);

sub get {
  my ( $self, $url ) = @_;

  my $deferred = deferred;

  my $data = $self->cache->get($url);
  if ( defined($data) ) {
    $deferred->resolve($data);
  }
  else {
    my $request = Dallycot::TextResolver::Request->new(
      ua            => $self->ua,
      url           => $url,
      canonical_url => $url,
    );
    $request->run->done(
      sub {
        ($data) = @_;
        $self->cache->set( $url, $data );
        $deferred->resolve($data);
      },
      sub {
        $deferred->reject(@_);
      }
    );
  }

  return $deferred->promise;
}

__PACKAGE__->meta->make_immutable;

1;
