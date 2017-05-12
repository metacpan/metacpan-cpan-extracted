package Articulate::Service;
use strict;
use warnings;

use Articulate::Syntax;

# The following provide objects which must be created on a per-request basis
use Articulate::Request;
use Articulate::Response;

use Moo;

with 'Articulate::Role::Service';
use Try::Tiny;
use Scalar::Util qw(blessed);

use Exporter::Declare;
default_exports qw(articulate_service);

=head1 NAME

Articulate::Service - provide an API to all the core Articulate
features.

=cut

=head1 DESCRIPTION

The Articulate Service provides programmatic access to all the core
features of the Articulate app. It is the intermediary between the
B<routes> and all other B<components>.

Mostly, you will want to be calling the service in routes, for
instance:

  get 'zone/:zone_name/article/:article_name' => sub {
    my ($zone_name, $article_name) = param('zone_name'), param('article_name');
    return $self->process_request ( read => "/zone/$zone_name/article/$article_name' )
  }

However, you may also want to call it from one-off scripts, tests,
etc., especially where you want to perform tasks which you don't want
to make available in routes, or where you are already in a perl
environment and mapping to the HTTP layer would be a distraction. In
theory you could create an application which did not have any web
interface at all using this service, e.g. a command-line app on a
shared server.

=cut

sub articulate_service {
  __PACKAGE__->new(@_);
}

has providers => (
  is      => 'rw',
  default => sub { [] },
  coerce  => sub { instantiate_array(@_) },
);

=head3 process_request

  my $response = service->process_request($request);
  my $response = service->process_request($verb => $data);

This is the primary method of the service: Pass in an
Articulate::Request object and the Service will produce a Response
object to match.

Alternatively, if you pass a string as the first argument, the request
will be created from the verb and the data.

Which verbs are handled, what data they require, and how they will be
processed are determined by the service providers you have set up in
your config: C<process_request> passes the request to each of the
providers in turn and asks them to process the request.

Providers can decline to process the request by returning undef, which
will cause the service to offer the requwst to the next provider.

Note that a provider MAY act on a request and still return undef, e.g.
to perform logging, however it is discouraged to perform acctions which
a user would typically expect a response from (e.g. a create action
should return a response and not just pass to a get to confirm it has
successfully created what it was suppsed to).

=cut

sub process_request {
  my $self       = shift;
  my @underscore = @_;   # because otherwise the try block will eat it
  my $request;
  my $response = new_response error => {
    error => Articulate::Error::NotFound->new(
      { simple_message => 'No appropriate Service Provider found' }
    )
  };
  try {
    if ( ref $underscore[0] ) {
      $request = $underscore[0];
    }
    else {               # or accept $verb => $data
      $request = new_request(@underscore);
    }
    foreach my $provider ( @{ $self->providers } ) {
      $provider->app( $self->app );
      my $resp = $provider->process_request($request);
      if ( defined $resp ) {
        $response = $resp;
        last;
      }
    }
  }
  catch {
    local $@ = $_;
    if ( blessed $_ and $_->isa('Articulate::Error') ) {
      $response = new_response error => { error => $_ };
    }
    else {
      $response =
        new_response error => { error =>
          Articulate::Error->new( { simple_message => 'Unknown error' . $@ } )
        };
    }
  };
  return $response;
}

=head3 enumerate_verbs

  my @verbs = @{ $self->enumerate_verbs };

Returns an arrayref of verbs which at list one provider will process.

=cut

sub enumerate_verbs {
  my $self  = shift;
  my $verbs = {};
  foreach my $provider ( @{ $self->providers } ) {
    $verbs->{$_}++ foreach keys %{ $provider->verbs };
  }
  return [ sort keys %$verbs ];
}

=head1 SEE ALSO

=over

=item * L<Articulate::Role::Service>

=item * L<Articulate::Request>

=item * L<Articulate::Response>

=back

=cut

1;
