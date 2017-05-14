package AnyEvent::eris::Server;
# ABSTRACT: eris pub/sub Server

use strict;
use warnings;
use Scalar::Util;
use Sys::Hostname;
use AnyEvent::Handle;
use AnyEvent::Socket;
use AnyEvent::Graphite;

my @_STREAM_NAMES     = qw(subscription match debug full regex);
my %_STREAM_ASSISTERS = (
    subscription => 'programs',
    match        => 'words',
);

# Precompiled Regular Expressions
my %_PRE = (
    program => qr/\s+\d+:\d+:\d+\s+\S+\s+([^:\s]+)(:|\s)/,
);

sub _server_error {
    my ( $self, $err_str, $fatal ) = @_;
    my $err_num = $!+0;
    AE::log debug => "SERVER ERROR: $err_num, $err_str";

    $fatal and $self->{'_cv'}->send;
}

my %client_commands = (
    fullfeed    => qr{^fullfeed},
    nofullfeed  => qr{^nofull(feed)?},
    subscribe   => qr{^sub(?:scribe)?\s(.*)},
    unsubscribe => qr{^unsub(?:scribe)?\s(.*)},
    match       => qr{^match (.*)},
    nomatch     => qr{^nomatch (.*)},
    debug       => qr{^debug},
    nobug       => qr{^no(de)?bug},
    regex       => qr{^re(?:gex)?\s(.*)},
    noregex     => qr{^nore(gex)?},
    status      => qr{^status},
    dump        => qr{^dump\s(\S+)},
    quit        => qr{(exit|q(uit)?)},
);

sub handle_subscribe {
    my ( $self, $handle, $SID, $args ) = @_;

    $self->remove_stream( $SID, 'full' );

    my @programs = map lc, split /[\s,]+/, $args;
    foreach my $program (@programs) {
        $self->clients->{$SID}{'subscription'}{$program} = 1;

        # number of registered programs
        $self->{'programs'}{$program}++;
    }

    $handle->push_write(
        'Subscribed to : '     .
        join( ',', @programs ) .
        "\n"
    );
}

sub handle_unsubscribe {
    my ( $self, $handle, $SID, $args ) = @_;

    my @programs = map lc, split /[\s,]+/, $args;
    foreach my $program (@programs) {
        delete $self->clients->{$SID}{'subscription'}{$program};

        --$self->{'programs'}{$program} <= 0
            and delete $self->{'programs'}{$program};
    }

    delete $self->clients->{$SID}{'subscription'};

    $handle->push_write(
        'Subscription removed for : ' .
        join( ',', @programs )        .
        "\n"
    );
}

sub handle_fullfeed {
    my ( $self, $handle, $SID ) = @_;

    $self->remove_all_streams($SID);

    $self->clients->{$SID}{'full'} = 1;

    $handle->push_write(
        "Full feed enabled, all other functions disabled.\n"
    );
}

sub handle_nofullfeed {
    my ( $self, $handle, $SID ) = @_;

    $self->remove_all_streams($SID);

    # XXX: Not in original implementation
    delete $self->clients->{$SID}{'full'};

    $handle->push_write("Full feed disabled.\n");
}

sub handle_match {
    my ( $self, $handle, $SID, $args ) = @_;

    $self->remove_stream( $SID, 'full' );

    my @words = map lc, split /[\s,]+/, $args;
    foreach my $word (@words) {
        $self->{'words'}{$word}++;
        $self->clients->{$SID}{'match'}{$word} = 1;
    }

    $handle->push_write(
        'Receiving messages matching : ' .
        join( ', ', @words )             .
        "\n"
    );
}

sub handle_nomatch {
    my ( $self, $handle, $SID, $args ) = @_;

    my @words = map lc, split /[\s,]+/, $args;
    foreach my $word (@words) {
        delete $self->clients->{$SID}{'match'}{$word};

        # Remove the word from searching if this was the last client
        --$self->{'words'}{$word} <= 0
            and delete $self->{'words'}{$word};
    }

    $handle->push_write(
        'No longer receiving messages matching : ' .
        join( ', ', @words )                       .
        "\n"
    );
}

sub handle_debug {
    my ( $self, $handle, $SID ) = @_;

    $self->remove_stream( $SID, 'full' );

    $self->clients->{$SID}{'debug'} = 1;
    $handle->push_write("Debugging enabled.\n");
}

sub handle_nobug {
    my ( $self, $handle, $SID ) = @_;

    $self->remove_stream( $SID, 'debug' );
    delete $self->clients->{$SID}{'debug'};
    $handle->push_write("Debugging disabled.\n");
}

sub handle_regex {
    my ( $self, $handle, $SID, $args ) = @_;

    # do not handle a regex if it's already full subscription
    $self->clients->{$SID}{'full'}
        and return;

    my $regex;
    eval {
        defined $args && length $args
            and $regex = qr{$args};
        1;
    } or do {
        my $error = $@ || 'Zombie error';

        $handle->push_write(
            "Invalid regular expression '$args', see: perldoc perlre\n"
        );

        return;
    };

    $self->clients->{$SID}{'regex'}{$regex} = 1;
    $handle->push_write(
        "Receiving messages matching regex : $args\n"
    );
}

sub handle_noregex {
    my ( $self, $handle, $SID ) = @_;

    $self->remove_stream( $SID, 'regex' );
    delete $self->clients->{$SID}{'regex'};
    $handle->push_write("No longer receiving regex-based matches\n");
}

sub handle_status {
    my ( $self, $handle, $SID ) = @_;
    my $clients      = $self->clients;
    my $client_count = scalar keys %{$clients};

    my @details = ();
    foreach my $stream (@_STREAM_NAMES) {
        # add streams from all SIDs
        my $stream_count = 0;
        my $assist_count = 0;
        foreach my $SID ( keys %{$clients} ) {
            $clients->{$SID}{$stream}
                and $stream_count++;

            my $assist; $assist = $_STREAM_ASSISTERS{$stream}
                and $assist_count += scalar keys %{ $self->{$assist} || {} };
        }

        $stream_count == 0
            and next;

        my $single_details = "$stream=$stream_count";
        $assist_count and $single_details .= ":$assist_count";

        push @details, $single_details;
    }

    my $details = join ', ', @details;
    $handle->push_write("STATUS[0]: $client_count connections: $details\n");
}

sub handle_dump {
    my ( $self, $handle, $SID, $type ) = @_;
    my $clients = $self->clients;

    my %dispatch = (
        assisters => sub {
            my @details = ();
            foreach my $asst ( values %_STREAM_ASSISTERS ) {
                $self->{$asst} or next;
                my @SIDs = grep $clients->{$_}{$asst}, keys %{$clients};
                push @details,
                     "$asst -> " . join ',', keys %{ $self->{$asst} };
            }

            return @details;
        },

        stats => sub {
            my @details = map +(
                "$_ -> $self->{'stats'}{$_}"
            ), keys %{ $self->{'stats'} };

            return @details;
        },

        streams => sub {
            my @details = ();

            foreach my $stream (@_STREAM_NAMES) {
                my @SIDs;
                foreach my $SID ( keys %{$clients} ) {
                    $clients->{$SID}{$stream}
                        or next;

                    my $stream_data = $clients->{$SID}{$stream};
                    push @SIDs, ref $stream_data eq 'HASH'
                              ? "$SID:" . join ',', keys %{$stream_data}
                              : $SID;
                }

                push @details, "$stream -> " . join '; ', @SIDs;
            }

            return @details;
        },
    );

    if ( my $cb = $dispatch{$type} ) {
        my @msgs = $cb->();
        my $msgs = join( "\n", @msgs ) . "\n";
        $handle->push_write($msgs);
    } else {
        $handle->push_write("DUMP[-1]: No comprende.\n");
    }
}

sub handle_quit {
    my ( $self, $handle, $SID ) = @_;
    $handle->push_write('Terminating connection on your request.');
    $self->hangup_client($SID);
    $self->{'_cv'}->send;
}

sub hangup_client {
    my ( $self, $SID ) = @_;
    delete $self->clients->{$SID};
    AE::log debug => "Client Termination Posted: $SID";
}

sub remove_stream {
    my ( $self, $SID, $stream ) = @_;
    AE::log debug => "Removing '$stream' for $SID";

    my $client_streams = delete $self->clients->{$SID}{'streams'}{$stream};

    # FIXME:
    # I *think* what this is supposed to do is delete assists
    # that were registered for this client, which it doesn't
    # - it deletes global assists instead - this needs to be
    # looked into
    if ($client_streams) {
        if ( my $assist = $_STREAM_ASSISTERS{$stream} ) {
            foreach my $key ( keys %{$client_streams} ) {
                --$self->{'assists'}{$assist}{$key} <= 0
                    and delete $self->{'assists'}{$assist}{$key}
            }
        }
    }
}

sub remove_all_streams {
    my ( $self, $SID ) = @_;
    foreach my $stream (@_STREAM_NAMES) {
        $self->remove_stream( $SID, $stream );
    }
}

sub new {
    my $class    = shift;
    my $hostname = ( split '.', hostname )[0];
    my $self     = bless {
        ListenAddress  => '127.0.0.1', # "localhost" doesn't work :/
        ListenPort     => 9514,
        GraphitePort   => 2003,
        GraphitePrefix => 'eris.dispatcher',
        hostname       => $hostname,

        @_,

        clients        => {},
        buffers        => {},
    }, $class;

    my ( $host, $port ) = @{$self}{qw<ListenAddress ListenPort>};
    Scalar::Util::weaken( my $inner_self = $self );

    $self->{'_tcp_server_guard'} ||= tcp_server $host, $port, sub {
        my ($fh) = @_
           or return $inner_self->_server_error($!);

        my $handle; $handle = AnyEvent::Handle->new(
            fh       => $fh,
            on_error => sub {
                my ( $hdl, $fatal, $msg ) = @_;
                my $SID = $inner_self->_session_id($hdl);
                $inner_self->hangup_client($SID);
                $inner_self->_server_error( $msg, $fatal );
                $hdl->destroy;
            },

            on_eof => sub {
                my ($hdl) = @_;
                my $SID = $inner_self->_session_id($hdl);
                $inner_self->hangup_client($SID);
                $hdl->destroy;
                AE::log debug => "SERVER, client $SID disconnected.";
            },

            on_read => sub {
                my ($hdl) = @_;
                chomp( my $line = delete $hdl->{'rbuf'} );
                my $SID = $inner_self->_session_id($hdl);

                foreach my $command ( keys %client_commands ) {
                    my $regex = $client_commands{$command};
                    if ( my ($args) = ( $line =~ /$regex/i ) ) {
                        my $method = "handle_$command";
                        return $inner_self->$method( $hdl, $SID, $args );
                    }
                }

                $hdl->push_write("UNKNOWN COMMAND, Ignored.\015\012");
            },
        );

        my $SID = $inner_self->_session_id($handle);
        $handle->push_write("EHLO Streamer (KERNEL: $$:$SID)\n");
        $inner_self->register_client( $SID, $handle );
    };

    $self->{'_timers'}{'flush'} = AE::timer 0.1, 0.1, sub {
        $inner_self->flush_client;
    };

    $self->{'_timers'}{'stats'} = AE::timer 0, 60, sub {
        $inner_self->stats;
    };

    # Statistics Tracking
    $self->{'config'}{'GraphiteHost'}
        and $self->graphite_connect;

    return $self;
}

sub flush_client {
    my $self    = shift;
    my $clients = $self->{'clients'};
    my $buffers = $self->{'buffers'};

    foreach my $SID ( keys %{$buffers} ) {
        my $msgs = $buffers->{$SID};
        @{$msgs} > 0 or next;

        # write the messages to the SID
        my $msgs_str = join "\n", @{$msgs};

        $clients->{$SID}{'handle'}->push_write("$msgs_str\n");
        $buffers->{$SID} = [];
    }
}

sub graphite_connect {
    my $self = shift;

    eval {
        $self->{'_graphite'} = AnyEvent::Graphite->new(
            host => $self->{'config'}{'GraphiteHost'},
            port => $self->{'config'}{'GraphitePort'},
        );

        1;
    } or do {
        my $error = $@ || 'Zombie error';
        AE::log debug => "Graphite server setup failed: $error";
    }
}

sub stats {
    my $self = shift;

    if ( ! exists $self->{'stats'} ) {
        $self->{'stats'} = {
            map +( $_ => 0 ), qw<
                received received_bytes dispatched dispatched _bytes
            >
        };

        return;
    }

    my $stats = delete $self->{'stats'};

    if ( $self->{'_graphite'} ) {
        my $time = AE::now;
        foreach my $stat ( keys %{$stats}) {
            my $metric = join '.', $self->{'config'}{'GraphitePrefix'},
                                   $self->{'hostname'},
                                   $stat;
            eval {
                $self->{'_graphite'}->send($metric, $stats->{$stat}, $time);
                1;
            } or do {
                my $error = $@ || 'Zombie error';
                AE::log debug => 'Error sending statistics, reconnecting.';
                $self->graphite_connect;
                last;
            }
        }
    }

    AE::log debug => 'STATS: ' .
                     join ', ', map "$_:$stats->{$_}", keys %{$stats};
}

sub run {
    my $self       = shift;
    $self->{'_cv'} = shift || AE::cv;
    $self->{'_cv'}->recv;
}

sub clients {
    my $self = shift;
    $self->{'clients'} ||= {};
}

sub register_client {
    my ( $self, $SID, $handle ) = @_;

    $self->clients->{$SID} = { handle => $handle };
}

sub dispatch_message {
    my ( $self, $msg ) = @_;
    $self->_dispatch_messages( [$msg] );
}

sub dispatch_messages {
    my ( $self, $msgs ) = @_;
    $self->_dispatch_messages( [ split /\n/, $msgs ] );
}

sub _dispatch_messages {
    my ( $self, $msgs ) = @_;

    my $clients    = $self->{'clients'};
    my $buffers    = $self->{'buffers'};
    my $dispatched = 0;
    my $bytes      = 0;

    # Handle fullfeeds
    foreach my $SID ( keys %{$clients} ) {
        push @{ $buffers->{$SID} }, @{$msgs};
        $dispatched += scalar @{$msgs};
        $bytes      += length $_ for @{$msgs};
    }

    foreach my $msg ( @{$msgs} ) {
        # Grab statitics;
        $self->{'stats'}{'received'}++;
        $self->{'stats'}{'received_bytes'} += length $msg;

        # Program based subscriptions
        if ( my ($program) = map lc, ( $msg =~ $_PRE{'program'} ) ) {
            # remove the sub process and PID from the program
            $program =~ s/\(.*//g;
            $program =~ s/\[.*//g;

            if ( exists $self->{'programs'}{$program} && $self->{'programs'}{$program} > 0 ) {
                foreach my $SID ( keys %{$clients} ) {
                    exists $clients->{$SID}{'subscription'}{$program}
                        or next;

                    push @{ $buffers->{$SID} }, $msg;
                    $dispatched++;
                    $bytes += length $msg;
                }
            }
        }

        # Match based subscriptions
        if ( keys %{ $self->{'words'} } ) {
            foreach my $word ( keys %{ $self->{'words'} } ) {
                if ( index ( $msg, $word ) != -1 ) {
                    foreach my $SID ( keys %{$clients} ) {
                        exists $clients->{$SID}{'match'}{$word}
                            or next;

                        push @{ $buffers->{$SID} }, $msg;
                        $dispatched++;
                        $bytes += length $msg;
                    }
                }
            }
        }

        # Regex based subscriptions
        if ( keys %{ $self->{'regex'} } ) {
            my %hit = ();
            foreach my $SID ( keys %{$clients} ) {
                foreach my $re ( keys %{ $clients->{$SID}{'regex'} } ) {
                    if ( $hit{$re} || $msg =~ /$re/ ) {
                        $hit{$re} = 1;
                        push @{ $buffers->{$SID} }, $msg;
                        $dispatched++;
                        $bytes += length $msg;
                    }
                }
            }
        }
    }

    # Report statistics for dispatched messages
    if ( $dispatched > 0 ) {
        $self->{'stats'}{'dispatched'}       += $dispatched;
        $self->{'stats'}{'dispatched_bytes'} += $bytes;
    }
}

sub _session_id {
    my ( $self, $handle ) = @_;
    # AnyEvent::Handle=HASH(0x1bb30f0)
    "$handle" =~ /\D0x([a-fA-F0-9]+)/;
    return $1;
}

1;

__END__

=pod

=head1 DESCRIPTION

L<AnyEvent::eris::Server> is an L<AnyEvent> version of
L<POE::Component::Server::eris> - a simple pub/sub implementation,
written by Brad Lhotsky.

Since I don't actually have any use for it right now, it's not
actively maintained. Might as well release it. If you're interested in
taking over it, just let me know.

For now the documentation is sparse but the tests should be clear
enough to assist in understanding it.
