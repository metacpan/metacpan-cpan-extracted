#!/usr/bin/env perl
use strict;
use warnings;
use AnyEvent;
use AnyEvent::Campfire::Client;
use Data::Printer;

my $cv = AnyEvent->condvar;

my $client = AnyEvent::Campfire::Client->new(
    token   => '',    # your token here
    rooms   => '',    # room number
    account => '',    # uh?
);

$client->on(
    'join',
    sub {
        my ( $e, $room ) = @_;
        print "joined room($room)\n";

        $client->lock(
            '535881',
            sub {
                my ( $body, $hdr ) = @_;
                if ( $hdr->{Status} !~ m/2/ ) {
                    $client->emit( 'error', "$hdr->{Status}: $hdr->{Reason}" );
                    $client->exit;
                }
                else {
                    print "$hdr->{Status}: locked room\n";
                    $client->unlock(
                        '535881',
                        sub {
                            my ( $body, $hdr ) = @_;
                            if ( $hdr->{Status} !~ m/2/ ) {
                                $client->emit( 'error',
                                    "$hdr->{Status}: $hdr->{Reason}" );
                                $client->exit;
                            }
                            else {
                                print "$hdr->{Status}: unlocked room\n";
                                $client->exit;
                            }
                        }
                    );
                }
            }
        );

        #    $client->put_room('535881', encode_json({ room => { name => 'Room 1', topic => 'oops' } }), sub {
        #        my ($body, $hdr) = @_;
        #        if ($hdr->{Status} !~ m/2/) {
        #            $client->emit('error', "$hdr->{Status}: $hdr->{Reason}");
        #        } else {
        #            print "$hdr->{Status}: updated room\n";
        #        }
        #
        #        $client->exit;
        #    });
        #
        #    $client->get_rooms(sub {
        #        my ($body, $hdr) = @_;
        #        if ($hdr->{Status} !~ m/2/) {
        #            $client->emit('error', "$hdr->{Status}: $hdr->{Reason}");
        #        } else {
        #            $body = encode_json($body) if 'HASH' eq ref($body);
        #            print "$hdr->{Status}: $body\n";
        #        }
        #
        #        $client->exit;
        #    });
    }
);
$client->on( 'error', sub { print "ERROR: $_[1]\n" } );
$client->on(
    'leave',
    sub {
        my ( $e, $room ) = @_;
        print "leaved room($room)\n";
    }
);

$client->on( 'exit', sub { $cv->send } );

$cv->recv;

__END__

=pod

=head1 SYNOPSIS

    you> say hello
    bot> hello
    you> leave
    bot> has left the room.

=cut
