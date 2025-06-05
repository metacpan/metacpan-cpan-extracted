package Bluesky::Poster;

use strict;
use warnings;
use LWP::UserAgent;
use JSON qw(encode_json decode_json);
use URI;
use Carp;

=head1 NAME

Bluesky::Poster - Simple interface for posting to Bluesky (AT Protocol)

=head1 SYNOPSIS

  use Bluesky::Poster;

  my $poster = Bluesky::Poster->new(
      handle       => 'your-handle.bsky.social',
      app_password => 'abcd-efgh-ijkl-mnop',
  );

  my $result = $poster->post("Hello from Perl!");
  print "Post URI: $result->{uri}\n";

=head1 DESCRIPTION

I've all but given up with X/Twitter.
It's API is overly complex and no longer freely available,
so I'm trying Bluesky.

This module authenticates with Bluesky using app passwords and posts text
messages using the AT Protocol API.

=head1 METHODS

=head2 new(handle => ..., app_password => ...)

Constructs a new poster object and logs in.

=head2 post($text)

Posts the given text to your Bluesky feed.

=cut

our $VERSION = '0.01';

sub new {
    my ($class, %args) = @_;

    for my $required (qw(handle app_password)) {
        croak "Missing required parameter: $required" unless $args{$required};
    }

    my $self = {
        handle       => $args{handle},
        app_password => $args{app_password},
        agent        => LWP::UserAgent->new,
        json         => JSON->new->utf8->canonical,
        session      => undef,
    };

    bless $self, $class;
    $self->_login;

    return $self;
}

sub _login {
    my ($self) = @_;
    my $ua = $self->{agent};

    my $res = $ua->post(
        'https://bsky.social/xrpc/com.atproto.server.createSession',
        'Content-Type' => 'application/json',
        Content => $self->{json}->encode({
            identifier => $self->{handle},
            password   => $self->{app_password},
        }),
    );

    unless ($res->is_success) {
        croak "Login failed: " . $res->status_line . "\n" . $res->decoded_content;
    }

    $self->{session} = $self->{json}->decode($res->decoded_content);
}

sub post {
    my ($self, $text) = @_;
    croak "Text is required" unless defined $text;

    my $now = time();
    my $iso_timestamp = _iso8601($now);

    my $payload = {
        repo   => $self->{session}{did},
        collection => 'app.bsky.feed.post',
        record => {
            '$type' => 'app.bsky.feed.post',
            text  => $text,
            createdAt => $iso_timestamp,
        },
    };

    my $res = $self->{agent}->post(
        'https://bsky.social/xrpc/com.atproto.repo.createRecord',
        'Content-Type'  => 'application/json',
        'Authorization' => 'Bearer ' . $self->{session}{accessJwt},
        Content => $self->{json}->encode($payload),
    );

    unless ($res->is_success) {
        croak "Post failed: " . $res->status_line . "\n" . $res->decoded_content;
    }

    return $self->{json}->decode($res->decoded_content);
}

sub _iso8601 {
    my $t = shift;
    my @gmt = gmtime($t);
    return sprintf(
        "%04d-%02d-%02dT%02d:%02d:%02dZ",
        $gmt[5]+1900, $gmt[4]+1, $gmt[3],
        $gmt[2], $gmt[1], $gmt[0],
    );
}

1;

=head1 AUTHOR

Nigel Horne, with help from ChatGPT

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

__END__
