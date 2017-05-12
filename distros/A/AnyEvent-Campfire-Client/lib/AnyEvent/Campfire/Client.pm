package AnyEvent::Campfire::Client;
{
  $AnyEvent::Campfire::Client::VERSION = '0.0.2';
}

# Abstract: Campfire API in an event loop
use Moose;
use namespace::autoclean;

use AnyEvent;
use AnyEvent::HTTP::ScopedClient;
use AnyEvent::Campfire::Stream;
use URI;
use MIME::Base64;
use JSON::XS;
use Try::Tiny;

extends 'AnyEvent::Campfire';

has 'account' => (
    is  => 'ro',
    isa => 'Str'
);

has 'uri' => (
    is         => 'ro',
    isa        => 'URI',
    lazy_build => 1,
);

sub _build_uri {
    my $account = shift->account;
    return URI->new("https://$account.campfirenow.com/");
}

sub BUILD {
    my $self = shift;

    if ( !$self->authorization || !scalar @{ $self->rooms } || !$self->account )
    {
        print STDERR
          "Not enough parameters provided. I Need a token, rooms and account\n";
        exit(1);
    }

    for my $room ( @{ $self->rooms } ) {
        $self->post(
            "/room/$room/join",
            sub {
                my ( $body, $hdr ) = @_;
                if ( $hdr->{Status} !~ m/^2/ ) {
                    $self->emit( 'error', "$hdr->{Status}: $hdr->{Reason}" );
                    return;
                }

                $self->emit( 'join', $room );

                my $stream = AnyEvent::Campfire::Stream->new(
                    token => $self->token,
                    rooms => join( ',', @{ $self->rooms } ),
                );

                $stream->on( 'stream', $self->_events->{message}[0] );
                $stream->on( 'error',  $self->_events->{error}[0] );
            }
        );
    }
}

sub speak {
    my ( $self, $room, $text ) = @_;

    $self->post(
        "/room/$room/speak",
        encode_json( { message => { body => $text } } ),
        sub {
            my ( $body, $hdr ) = @_;
            if ( !$body || $hdr->{Status} !~ m/^2/ ) {
                $self->emit( 'error', $hdr->{Reason} );
                return;
            }
        }
    );
}

sub leave {
    my ( $self, $room ) = @_;

    $self->post(
        "/room/$room/leave",
        sub {
            my ( $body, $hdr ) = @_;
            if ( !$body || $hdr->{Status} !~ m/^2/ ) {
                $self->emit( 'error', "$hdr->{Status}: $hdr->{Reason}" );
                return;
            }

            $self->emit( 'leave', $room );
            $self->emit('exit') if ( $room eq @{ $self->rooms }[-1] );
        }
    );
}

sub exit {
    my $self = shift;
    for my $room ( @{ $self->rooms } ) {
        $self->leave($room);
    }
}

sub get_account {
    my ( $self, $callback ) = @_;
    $self->get( '/account', $callback );
}

sub recent {
    my ( $self, $room, $opt, $callback ) = @_;
    return unless $room;

    if ( 'CODE' eq ref $opt ) {
        $callback = $opt;
    }
    else {
        # limit, since_message_id
        $self->uri->query_form($opt);
    }

    $self->get( "/room/$room/recent", $callback );
}

sub get_rooms {
    my ( $self, $callback ) = @_;
    $self->get( '/rooms', $callback );
}

sub put_room {
    my ( $self, $room, $room_info, $callback ) = @_;
    $room_info = encode_json($room_info) if ref($room_info) eq 'HASH';
    $self->put( "/room/$room", $room_info, $callback );
}

sub lock {
    my ( $self, $room, $callback ) = @_;
    $self->post( "/room/$room/lock", $callback );
}

sub unlock {
    my ( $self, $room, $callback ) = @_;
    $self->post( "/room/$room/unlock", $callback );
}

sub request {
    my ( $self, $method, $path, $reqBody, $callback ) = @_;

    $self->uri->path($path);
    my $scope = AnyEvent::HTTP::ScopedClient->new( $self->uri );
    $scope->header(
        {
            Authorization  => $self->authorization,
            Accept         => 'application/json',
            'Content-Type' => 'application/json',
        }
    )->request( $method, $reqBody, $callback );
    $self->uri->query_form('');    # clear query
}

sub get    { shift->request( 'GET',    @_ ) }
sub post   { shift->request( 'POST',   @_ ) }
sub put    { shift->request( 'PUT',    @_ ) }
sub delete { shift->request( 'DELETE', @_ ) }

__PACKAGE__->meta->make_immutable;

1;


1;

__END__

=pod

=encoding utf-8

=head1 NAME

AnyEvent::Campfire::Client

=head1 VERSION

version 0.0.2

=head1 SYNOPSIS

    use AnyEvent::Campfire::Client;
    my $client = AnyEvent::Campfire::Client->new(
        token => 'xxxx',
        rooms => '1234',
        account => 'p5-hubot',
    );

    $client->on(
        'join',
        sub {
            my ($e, $room_id) = @_; # $e is event emitter. please ignore it.
            $client->speak($room_id, "hi");
        }
    );

    $client->on(
        'message',
        sub {
            my ($e, $data) = @_;
            # ...
        }
    );

    ## want to exit?
    $client->exit;

=head1 AUTHOR

Hyungsuk Hong <hshong@perl.kr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Hyungsuk Hong.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
