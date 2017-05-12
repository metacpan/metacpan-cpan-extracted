use strict;
use Test::More tests => 30;
use Test::TCP;
use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Socket;
use AnyEvent::HTTP::MXHR;
use JSON;

test_tcp(
    server => sub {
        my $port = shift;

        my $apoptosis; $apoptosis = AE::timer 60, 0, sub {
            kill TERM => $$;
            undef $apoptosis;
        };

        my $server = tcp_server undef, $port, sub {
            my $fh = shift;
            my $handle = AnyEvent::Handle->new( fh => $fh );

            $handle->push_write(
                "HTTP/1.0 200 ok\r\n" .
                "Content-Type: multipart/mixed; boundary=\"AAABBBCCC\"\r\n\r\n" .
                " " x 2048 . # dummy whitespace required to work with IE
                "\n--AAABBBCCC\n"
            );

            my $i = 1;
            # XXX for some reaason it seems like fork-then-start anyevent
            # has a weird side effect where a watcher's first invocation
            # is executed twice...?
            my $w; $w = AE::timer 1, 1, sub {
                $handle->push_write(
                    "Content-Type: application/json\r\n\r\n" .
                    qq|{ "foo": "bar", "bar": "baz", "seq": $i }| . "\n" .
                    "--AAABBBCCC"
                );
                if ($i++ >= 10) {
                    undef $w;
                }
            };
            my $quit = sub {
                undef $w;
                undef $handle;
            };

            $handle->on_error($quit);
            $handle->on_eof($quit);
        };

        my $cv = AE::cv {
            undef $server;
        };
        my $s; $s = AE::signal TERM => sub {
            undef $s;
            $cv->send;
        };

        $cv->recv;
    },
    client => sub {
        my $port = shift;

        my $apoptosis; $apoptosis = AE::timer 60, 0, sub {
            kill TERM => $$;
            undef $apoptosis;
        };
        my $seq = 1;
        my $guard;
        my $cv = AE::cv { undef $guard };
        my $quit = sub {
            $cv->send();
        };
        $guard = mxhr_get "http://127.0.0.1:$port",
            on_error => $quit,
            on_eof   => $quit,
            sub {
                my ($body, $headers) = @_;

                if ($headers->{'content-type'} =~ /^application\/json/) {
                    ok(1, "json received");
                    my $json = eval { decode_json $body };
                    ok ($json, "JSON decoded OK");
                    ok ($json->{seq} <= $seq, "seq ok $seq");
                    if ($seq == $json->{seq}) { $seq++ } # see above XXX
                } else {
                    ok(0, "unknown content-type: $headers->{'content-type'}");
                    ok(0, "don't know how to handle data");
                    ok(0, "don't know how to get seq");
                    $seq++;
                }

                if($seq > 10)  {
                    $quit->();
                    return;
                }
                return 1;
            }
         ;

        $cv->recv;
    },
);