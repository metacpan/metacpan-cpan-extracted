package Articulate::Request;
use strict;
use warnings;

use Moo;
use Articulate::Service;

=head1 NAME

Articulate::Request - represent a request

=cut

=head1 FUNCTIONS

=head3 new_request

  my $request = new_request verb => $data;

Creates a new request, using the verb and data supplied as the
respective arguments.

=cut

use Exporter::Declare;
default_exports qw(new_request);

sub new_request {
  __PACKAGE__->new(
    {
      verb => shift,
      data => shift
    }
  );
}

=head1 METHODS

=head3 new

An unremarkable Moo constructor.

=cut

=head3 perform

Sends the to the articulate service.

Note: the behaviour of this method may change!

=cut

sub perform {
  service->process_request(shift);
}

=head1 ATTRIBUTES

=head3 verb

The action being performed, e.g. C<create>, C<read>, etc. The verbs
available are entirely dependant on the application: A request will be
handled by a service provider (see Articulate::Service) which will
typically decide if it can fulfil the request based on the verb.

=cut

has verb => (
  is      => 'rw',
  default => sub { 'error' }
);

=head3 data

The information passed along with the request, e.g. C<< { location =>
'/zone/public/article/hello-world' } >>. This should always be a
hashref.

=cut

has data => (
  is      => 'rw',
  default => sub { {} }
);

=head3 app

The app for which the request has been made.

=cut

has app => (
  is       => 'rw',
  weak_ref => 1,
);

=head3 user_id

The user_id making the request. This is typically inferred from the
framework.

=cut

has user_id => (
  is      => 'rw',
  lazy    => 1,
  default => sub {
    my $self = shift;
    return undef unless $self->app;
    return undef unless $self->app->components->{framework};
    return $self->app->components->{framework}->user_id;
  }
);

1;
