package AnyEvent::ReverseHTTP;

use strict;
use 5.008_001;
our $VERSION = '0.05';

use Carp;
use AnyEvent::Util;
use AnyEvent::HTTP;
use HTTP::Request;
use HTTP::Response;
use URI::Escape;
use Scalar::Util;

use base qw(Exporter);
our @EXPORT = qw(reverse_http);

use Any::Moose;

has endpoint => (
    is => 'rw', isa => 'Str',
    required => 1, default => "http://www.reversehttp.net/reversehttp",
);

has label => (
    is => 'rw', isa => 'Str',
    required => 1,
    lazy => 1, default => sub {
        require Digest::SHA;
        require Time::HiRes;
        return Digest::SHA::sha1_hex($$ . Time::HiRes::gettimeofday() . {});
    },
);

has token => (
    is => 'rw', isa => 'Str',
    default => '-',
);

has on_register => (
    is => 'rw', isa => 'CodeRef',
    default => sub { sub { warn "Public Application URL: $_[0]\n" } },
);

has on_error => (
    is => 'rw', isa => 'CodeRef',
    default => sub { sub { Carp::croak(@_) } },
);

has on_request => (
    is => 'rw', isa => 'CodeRef',
    default => sub { sub { Carp::croak("on_request handler is not defined!") } },
);

sub reverse_http {
    my $cb = pop;

    my @args =
        @_ == 1 ? qw(label) :
        @_ == 2 ? qw(label token) :
        @_ >= 3 ? qw(endpoint label token) : ();

    my %args; @args{@args} = @_;
    return __PACKAGE__->new(%args, on_request => $cb)->connect;
}

sub connect {
    my $self = shift;

    my %query = (name => $self->label);
    $query{token} = $self->token if $self->token;

    my $body = join "&", map "$_=" . URI::Escape::uri_escape($query{$_}), keys %query;

    http_post $self->endpoint, $body, sub {
        my($body, $hdr) = @_;

        if ($hdr->{Status} eq '201' || $hdr->{Status} eq '204') {
            my $app_url = _extract_link($hdr, 'related');
            $self->on_register->($app_url);
        } else {
            return $self->on_error->("$hdr->{Status}: $hdr->{Reason}");
        }

        my $poller; $poller = sub {
            my($body, $hdr) = @_;

            if ($hdr->{Status} eq '200') {
                my $req  = HTTP::Request->parse($body);
                $req->header('Requesting-Client', $hdr->{'requesting-client'});
                my $res  = $self->on_request->($req);

                my $postback = sub {
                    my $res = shift;

                    # Duck typing for as_string, but accepts plaintext too for 200
                    unless (Scalar::Util::blessed($res) && $res->can('as_string')) {
                        my $content = $res;
                        $res = HTTP::Response->new(200);
                        $res->content_type('text/plain');
                        $res->content($content);
                    }

                    $res->protocol("HTTP/1.1"); # Upgrade since reversehttp.net requires so

                    # HTTP::Response->as_string by default adds a new line which could be harmful
                    my $res_body = $res->as_string;
                    chomp $res_body if $res->content_type eq 'text/plain';

                    http_post $hdr->{URL}, $res_body,
                        headers => { 'content-type' => 'message/http' },
                        sub {
                            my($body, $hdr) = @_;
                            if ($hdr->{Status} ne '202') {
                                $self->on_error->("$hdr->{Status}: $hdr->{Reason}");
                            }
                        };
                };

                # Return condvar to pass back to event loop
                if (Scalar::Util::blessed($res) && $res->isa('AnyEvent::CondVar')) {
                    $res->cb(sub { $postback->($res->recv) });
                } else {
                    $postback->($res);
                }
            }

            my $next = _extract_link($hdr, 'next');
            http_get $next, $poller;
        };

        my $url = _extract_link($hdr, 'first');
        http_get $url, $poller;
    };

    return AnyEvent::Util::guard { undef $self };
}

sub _extract_link {
    my($hdr, $rel) = @_;
    my @links = $hdr->{link} =~ /<([^>]*)>;\s*rel="\Q$rel\E"/g;
    return $links[0];
}

no Any::Moose;
__PACKAGE__->meta->make_immutable;

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

AnyEvent::ReverseHTTP - reversehttp for AnyEvent

=head1 SYNOPSIS

  use AnyEvent::ReverseHTTP;

  # simple Hello World server
  my $guard = reverse_http "myserver123", "token", sub {
      my $req = shift;
      return "Hello World"; # You can return HTTP::Response object for more control
  };

  # more controls over options and callbacks
  my $server = AnyEvent::ReverseHTTP->new(
      endpoint => "http://www.reversehttp.net/reversehttp",
      label    => "aedemo1234",
      token    => "mytoken",
  );

  $server->on_register(sub {
      my $pub_url = shift;
  });

  $server->on_request(sub {
      my $req = shift;
      # $req is HTTP::Request, return HTTP::Response or AnyEvent::CondVar that receives it
  });

  my $guard = $server->connect;

  AnyEvent->condvar->recv;

=head1 DESCRIPTION

AnyEvent::ReverseHTTP is an AnyEvent module that acts as a Reverse
HTTP server (which is actually a polling client for Reverse HTTP
gateway).

This module implements simple Reverse HTTP client that's tested
against I<reversehttp.net> demo server. More complicated specification
like relaying or pipelining is not (yet) implemented.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://www.reversehttp.net/reverse-http-spec.html>

=cut
