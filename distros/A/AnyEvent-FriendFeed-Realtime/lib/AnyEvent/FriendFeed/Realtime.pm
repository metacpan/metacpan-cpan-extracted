package AnyEvent::FriendFeed::Realtime;

use strict;
use 5.008_001;
our $VERSION = '0.05';

use AnyEvent;
use AnyEvent::HTTP;
use Encode;
use JSON;
use MIME::Base64;
use Scalar::Util;
use URI;
use URI::QueryParam;

sub new {
    my($class, %args) = @_;

    my $headers = {};
    if ($args{username}) {
        my $auth = MIME::Base64::encode( join(":", $args{username}, $args{remote_key}) );
        $headers->{Authorization} = "Basic $auth";
    }

    my $uri = URI->new("http://friendfeed-api.com/v2/updates$args{request}");
    $uri->query_param(updates => 1);

    my $self = bless {}, $class;

    my $long_poll; $long_poll = sub {
        http_get $uri, headers => $headers, on_header => sub {
            my $hdrs = shift;
            if ($hdrs->{Status} ne '200') {
                ($args{on_error} || sub { die @_ })->("$uri: $hdrs->{Status} $hdrs->{Reason}");
                return;
            }
            return 1;
        }, sub {
            my($body, $headers) = @_;
            return $long_poll->() unless $body;
            my $res = eval { JSON::decode_json($body) } || do {
                ($args{on_error} || sub { die @_ })->("JSON parsing error: $@");
                return;
            };

            if ($res->{errorCode}) {
                ($args{on_error} || sub { die @_ })->($res->{errorCode});
                return;
            }

            for my $entry (@{$res->{entries}}) {
                ($args{on_entry} || sub {})->($entry);
            }

            if ($res->{realtime}) {
                $uri = $uri->clone;
                $uri->query_param(cursor => $res->{realtime}{cursor});
                $long_poll->();
            }
        }
    };

    $self->{guard} = AnyEvent::Util::guard { undef $long_poll };

    $long_poll->();

    return $self;
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

AnyEvent::FriendFeed::Realtime - Subscribe to FriendFeed Real-time API

=head1 SYNOPSIS

  use AnyEvent::FriendFeed::Realtime;

  my $client = AnyEvent::FriendFeed::Realtime->new(
      username   => $user,        # optional
      remote_key => $remote_key,  # optional: https://friendfeed.com/account/api
      request    => "/feed/home", # or "/feed/NICKNAME/friends", "/search?q=friendfeed"
      on_entry   => sub {
          my $entry = shift;
          # See http://friendfeed.com/api/documentation for the data structure
      },
  );

=head1 DESCRIPTION

AnyEvent::FriendFeed::Realtime is an AnyEvent consumer that subscribes
to FriendFeed Real-time API via JSON long-poll.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<AnyEvent::HTTP>, L<AnyEvent::Twitter::Stream>, L<http://friendfeed.com/api/documentation>

=cut
