package AnyEvent::WebService::Notifo;
BEGIN {
  $AnyEvent::WebService::Notifo::VERSION = '0.001';
}

# ABSTRACT: AnyEvent-powered client for the notifo.com API

use strict;
use warnings;
use parent 'Protocol::Notifo';
use AnyEvent::HTTP;

sub send_notification {
  my ($self, %args) = @_;

  my $cb = delete $args{cb};
  confess("Missing required parameter 'cb', ") unless $cb;

  ## Accept both coderef's and condvar's
  unless (ref($cb) eq 'CODE') {
    my $cv = $cb;
    $cb = sub { $cv->send(@_) };
  }

  my $req = $self->SUPER::send_notification(%args);
  return $self->_do_request($cb, $req);
}

sub _do_request {
  my ($self, $cb, $req) = @_;

  my ($meth, $url, $body, $hdrs) = @$req{qw(method url body headers)};

  return http_request(
    $meth   => $url,
    body    => $body,
    headers => {@$hdrs},
    sub { $self->_do_response($cb, @_) }
  );
}

sub _do_response {
  my ($self, $cb, $data, $h) = @_;

  my $res = $self->parse_response(
    http_response_code => $h->{Status},
    http_body          => $data,
    http_status_line   => "$h->{Status} $h->{Reason}",
  );

  $cb->($res);
}

1;


__END__
=pod

=head1 NAME

AnyEvent::WebService::Notifo - AnyEvent-powered client for the notifo.com API

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use AnyEvent;
    use AnyEvent::WebService::Notifo;
    
    # Uses the default values obtained from configuration file
    my $awn = AnyEvent::WebService::Notifo->new;
    
    # ... or just pass them in
    my $awn = AnyEvent::WebService::Notifo->new(
        api_key => 'api_key_value',
        user    => 'api_user',
    );
    
    # a coderef as a callback is one possibility...
    $awn->send_notification(msg => 'my nottification text', cb => sub {
      my ($res) = @_;
      # $res is our response 
    });
    
    # ... or a condvar
    my $cv = AE::cv;
    $awn->send_notification(msg => 'my nottification text', cb => $cv);
    $res = $cv->recv;  # $res is our response

=head1 DESCRIPTION

A client for the L<http://notifo.com/> API using the L<AnyEvent> framework.

=head1 CONSTRUCTORS

=head2 new

Creates a new C<AnyEvent::WebService::Notifo> object. See
L<< Protocol::Notifo->new()|Protocol::Notifo/new >>
for a explanation of the parameters and the configuration file used for
default values.

=head1 METHODS

=head2 send_notification

Sends a notification.

It accepts a hash with parameters. We require a C<cb> parameter. This
must be a coderef or a condvar, that will be called with the response.

In void context, this method returns nothing. In scalar context, it
returns a guard object. If this object goes out of scope, the request is
canceled. So you need to keep this guard object alive until your
callback is called.

See
L<< Protocol::Notifo->send_notification()|Protocol::Notifo/send_notification >>
for list of parameters that this method accepts, and an explanation of
the response that the callback receives.

=head1 SEE ALSO

L<Protocol::Notifo>, L<AnyEvent>

=head1 AUTHOR

Pedro Melo <melo@simplicidade.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010 by Pedro Melo.

This is free software, licensed under:

  The Artistic License 2.0

=cut

