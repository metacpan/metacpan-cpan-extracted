use strict;
use warnings;
use Test::More;
use Net::EmptyPort qw(empty_port);
use AnyEvent::Socket qw(tcp_server);
use AnyEvent::Handle;
use AnyEvent::Connector;

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

sub setup_echo_proxy {
    my $port = empty_port();
    my $cv = AnyEvent->condvar;
    my $proxied_data = "";
    my $cb_established = sub {
        my ($h) = @_;
        my $got_data = delete $h->{rbuf};
        $proxied_data .= $got_data;
        $h->push_write($got_data);
    };
    my $connect_req = "";
    my $cb_receive_conn = sub {
        my ($h) = @_;
        $connect_req .= delete $h->{rbuf};
        if($connect_req !~ /\r\n\r\n$/) {
            return;
        }
        $h->push_write(qq{HTTP/1.1 200 OK\r\nX-Hoge-Header: hogehoge\r\n\r\n});
        $h->on_read($cb_established);
    };
    my @error;
    my $finish = sub {
        $cv->send([$connect_req, $proxied_data, \@error]);
    };
    my $server = tcp_server "127.0.0.1", $port, sub {
        my ($fh) = @_;
        my $ah;
        $ah = AnyEvent::Handle->new(
            fh => $fh,
            on_error => sub {
                my ($h, $fatal, $msg) = @_;
                push @error, [$fatal, $msg];
                $ah->destroy();
                undef $ah;
                $finish->();
            },
            on_eof => sub {
                $ah->destroy();
                undef $ah;
                $finish->();
            },
            on_read => $cb_receive_conn
        );
    };
    return ($port, $server, $cv);
}

sub setup_closing_proxy {
    my $port = empty_port();
    my $server = tcp_server '127.0.0.1', $port, sub {
        my ($fh) = @_;
        my $ah;
        $ah = AnyEvent::Handle->new(
            fh => $fh,
            on_error => sub {
                $ah->push_shutdown();
                undef $ah;
                close $fh;
                undef $fh;
            },
        );
        $ah->push_read(line => sub {
            my ($h) = @_;
            $h->push_shutdown();
            undef $h;
            close $fh;
            undef $fh;
        });
    };
    return ($port, $server);
}

sub setup_send_junk_proxy {
    my ($port) = empty_port();
    my $server = tcp_server '127.0.0.1', $port, sub {
        my ($fh) = @_;
        my $ah;
        $ah = AnyEvent::Handle->new(
            fh => $fh,
            on_error => sub {
                undef $ah;
                close $fh;
                undef $fh;
            },
            on_read => sub {
                if($ah->{rbuf} !~ /\r\n\r\n$/) {
                    return;
                }
                delete $ah->{rbuf};
                $ah->push_write("some junk\r\n");
                $ah->push_shutdown();
                undef $ah;
            },
        );
    };
    return ($port, $server);
}


subtest 'successful echo proxy', sub {
    my ($proxy_port, $proxy_guard, $proxy_cv) = setup_echo_proxy();
    my $conn = AnyEvent::Connector->new(
        proxy => "http://127.0.0.1:$proxy_port"
    );
    my $client_cv = AnyEvent->condvar;
    my ($got_host, $got_port);
    $conn->tcp_connect("this.never.exist.i.guess.com", 5500, sub {
        (my $fh, $got_host, $got_port) = @_;
        my $ah;
        $ah = AnyEvent::Handle->new(
            fh => $fh,
            on_error => sub {
                my ($h, $fatal, $msg) = @_;
                $ah->destroy();
                undef $ah;
                $client_cv->croak($fatal, $msg);
            },
            on_eof => sub {
                undef $ah;
                $client_cv->send();
            },
            on_read => sub {
                my ($h) = @_;
                my $data = delete $h->{rbuf};
                $ah->push_shutdown();
                $ah->destroy();
                undef $ah;
                $client_cv->send(delete $h->{rbuf});
            }
        );
        $ah->push_write("data submitted\n");
        $ah->push_read(line => sub {
            my ($h, $line) = @_;
            $ah->push_shutdown();
            $ah->destroy();
            undef $ah;
            $client_cv->send($line);
        });
    });
    my $client_got = $client_cv->recv();
    my $proxy_got = $proxy_cv->recv();
    is $client_got, "data submitted";
    is $got_host, "127.0.0.1";
    is $got_port, $proxy_port;
    is $proxy_got->[0], "CONNECT this.never.exist.i.guess.com:5500 HTTP/1.1\r\nHost: this.never.exist.i.guess.com:5500\r\n\r\n";
    is $proxy_got->[1], "data submitted\n";
    is_deeply $proxy_got->[2], [];
};

subtest "proxy error", sub {
    my ($proxy_port, $proxy_guard) = setup_closing_proxy();
    my $conn = AnyEvent::Connector->new(
        proxy => "http://127.0.0.1:$proxy_port"
    );
    my $client_cv = AnyEvent->condvar;
    $conn->tcp_connect("foo.bar.com", 1888, sub {
        my (@args) = @_;
        $client_cv->send(\@args);
    });
    my $client_got = $client_cv->recv();
    is_deeply $client_got, [], "no arg passed to connect_cb because of proxy error";
};

subtest "proxy not exist", sub {
    my $no_port = empty_port();
    my $conn = AnyEvent::Connector->new(
        proxy => "http://127.0.0.1:$no_port"
    );
    my $client_cv = AnyEvent->condvar;
    $conn->tcp_connect("foo.bar.com", 1888, sub {
        my (@args) = @_;
        $client_cv->send(\@args);
    });
    my $client_got = $client_cv->recv();
    is_deeply $client_got, [], "no arg passed to connect_cb because there is no proxy listening.";
};

subtest "proxy sending junk", sub {
    my ($port, $proxy) = setup_send_junk_proxy();
    my $conn = AnyEvent::Connector->new(
        proxy => "http://127.0.0.1:$port"
    );
    my $client_cv = AnyEvent->condvar;
    $conn->tcp_connect("foo.bar.com", 12222, sub {
        my (@args) = @_;
        $client_cv->send(\@args);
    });
    my $client_got = $client_cv->recv();
    is_deeply $client_got, [], "proxy sending junk causes failure.";
};

is_deeply \@warnings, [], "no warnings";

done_testing;
