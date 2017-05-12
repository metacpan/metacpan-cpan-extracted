#!/usr/bin/env perl

{

    package My::Plugin::Talker;
    use Cogwheel;
    extends qw(Cogwheel::Plugin);

    use POE;
    use POE::Filter::Line;

    use strict;
    use warnings;

    has __conlist__ => (
        isa     => 'HashRef',
        is      => 'rw',
        default => sub { {} },
    );

    sub add_plugin {
        my ( $self, $server ) = @_;
        $server->_log( v => 4, msg => "Talker plugin added" );
    }

    # ---------------------------------------------------------
    # server

    sub local_connected {
        my ( $self, $server, $con, $socket ) = @_;

        $self->take_connection($con);
        my $filter = $con->filter;

        # POE::Filter::Stackable object:
        $filter->push( POE::Filter::Line->new() );
        $filter->shift();    # POE::Filter::Stream

        # welcome message
        $con->send("Welcome to the chat server");
        $con->send("/nick <nickname>  | change your nickname");
        $con->send("/quit             | leave chat");

        $con->x->{nick} = 'guest' . $con->ID;

        my @nicks = map {
            my $c = $server->get_connection($_);
            ( $c && $c->ID ne $con->ID ) ? $c->x->{nick} : ();
        } $self->con_list;

        if (@nicks) {
            $con->send( "People here: " . join( ',', @nicks ) );
        }
        else {
            $con->send("You are alone");
        }

        $con->call( broadcast => $con->x->{nick} . ' connected' );
    }

    sub local_receive {
        my ( $self, $server, $con, $data ) = @_;

        $self->_log( v => 4, msg => $data );

        if ( $data =~ m!^/quit!i ) {
            $con->send("goodbye.");
            $con->close();
        }
        elsif ( $data =~ m!^/nick (.*)!i ) {
            $con->send("nickname changed to $1");
            $con->call(
                broadcast => $con->x->{nick} . ' is now known as ' . $1 );
            $con->x->{nick} = $1;
        }
        elsif ($data) {
            $con->call( broadcast => $con->x->{nick} . ': ' . $data );
        }
    }

    sub local_disconnected {
        my ( $self, $server, $con ) = @_;

        $self->_log( v => 4, msg => ' connection went away' );

        if ( my $nick = $con->x->{nick} ) {

            # tell everyone the message
            foreach ( $self->con_id_list ) {
                if ( my $c = $server->get_connection($_) ) {
                    $c->send("$nick disconnected");
                }
            }
        }

    }

    sub broadcast {
        my ( $self, $server, $con, $data ) = @_;

        # person sending the message
        my $id   = $con->ID;
        my $nick = $con->x->{nick};

        # tell everyone the message
        foreach ( $self->con_id_list ) {

            # skip ourself
            next if ( $_ eq $id );

            if ( my $c = $server->get_connection($_) ) {
                $c->send($data);
            }
        }
    }
}

{

    package Talker;
    use Moose;

    BEGIN { extends qw(Cogwheel::Server); }

    has '+name'           => ( default => 'Chat Server' );
    has '+listen_address' => ( default => '0.0.0.0' );
    has '+listen_port'    => ( default => 9999 );

    no Moose;
}

package main;
use lib qw( lib );
my $s = Talker->new(
    Plugins => [
        {
            Plugin   => My::Plugin::Talker->new(),
            Priority => 0,
        }
    ],
);
POE::Kernel->run();

1;
