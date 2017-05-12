#!/usr/bin/perl -w

use 5.014;
use Log::Any qw($log);
use Log::Any::Adapter;
use Log::Dispatch;
use AnyEvent;
use AnyEvent::Socket;
use AnyEvent::Handle;
use Protocol::WebSocket::Handshake::Server;
use Protocol::WebSocket::Frame;
use JSON::XS;
use URI::Escape;

my $tcp_server;
my %clients;
my %chromi;
my %requests;

sub start_server
{
    $tcp_server = AnyEvent::Socket::tcp_server undef, 7441, sub {
        my ($fh, $host, $port) = @_;

        $log->info("connected (host: $host, port: $port)");
     
        my $ws_handshake = Protocol::WebSocket::Handshake::Server->new;
        my $ws_frame = Protocol::WebSocket::Frame->new;
     
        my $handle = AnyEvent::Handle->new(fh => $fh);
        $clients{$handle} = { host => $host, port => $port };

        $handle->on_error(
            sub {
                my ($handle, $fatal, $message);
                if($fatal) {
                    $log->error("connection error: $message");
                }
                else {
                    $log->warning("connection error: $message");
                }
            }
        );

        $handle->on_eof(
            sub {
                $log->info("disconnected: $host:$port");
                delete $clients{$handle};
                delete $chromi{$handle};
            }
        );
     
        $handle->on_read(
            sub {
                my $chunk = $handle->{rbuf};
                $handle->{rbuf} = undef;
     
                # Handshake
                if (!$ws_handshake->is_done) {
                    $ws_handshake->parse($chunk);
                    if ($ws_handshake->is_done) {
                        $handle->push_write($ws_handshake->to_string);
                    }
                }
                $ws_handshake->is_done() or return;
     
                # Data
                $ws_frame->append($chunk);
                while (my $message = $ws_frame->next) {
                    if($message =~ /^Chromi (\d+) (\w+) (.*)$/) {
                        # Chrome to Client

                        my ($id, $status, $reply) = ($1, $2, $3);
                        if(defined $requests{$id}) {
                            my $c = $requests{$id};
                            if(defined $clients{$c}) {
                                my $frame = Protocol::WebSocket::Frame->new($message);
                                $log->debug("sending reply for $id");
                                $c->push_write($frame->to_bytes);
                            }
                        }
                        delete $requests{$id};
                    }
                    elsif($message =~ /^Chromi \S+ info connected/) {
                        $log->info("chrome detected (host: $host, port: $port)");
                        $chromi{$handle}{handle} = $handle;
                        delete $clients{$handle};
                    }
                    elsif($message =~ /^Chromi \S+ info heartbeat/) {
                    }
                    elsif($message =~ /^chromi (\d+) \S+ .*$/) {
                        # Client to Chrome

                        $log->info("received: $message");
                        # register who made the request
                        $requests{$1} = $handle;
                        # chrome isn't connected
                        if(not scalar keys %chromi) {
                            my $reply = "Chromi $1 error " . uri_escape(encode_json({ error => 'chrome not connected'}));
                            my $frame = Protocol::WebSocket::Frame->new($reply);
                            $handle->push_write($frame->to_bytes);
                        }
                        else {
                            for my $key (keys %chromi) {
                                my $c = $chromi{$key}{handle};
                                my $frame = Protocol::WebSocket::Frame->new($message);
                                $c->push_write($frame->to_bytes);
                            }
                        }
                    }
                    else {
                        $log->info("other: $message");
                    }
                }
            }
        );
    };
}

sub main()
{
    my $ld_log = Log::Dispatch->new(
       outputs => [
	    [ 'Syslog', min_level => 'info', ident  => 'chrome-siteshow' ],
	    [ 'Screen', min_level => 'debug', newline => 1 ],
	]
    );
    Log::Any::Adapter->set( 'Dispatch', dispatcher => $ld_log );

    $log->info("starting up");
    my $cv = AnyEvent->condvar;
    start_server();
    $cv->wait();
}

main;
