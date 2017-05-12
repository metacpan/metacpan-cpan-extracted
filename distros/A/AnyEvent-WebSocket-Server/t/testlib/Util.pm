package testlib::Util;
use strict;
use warnings;
use Exporter qw(import);
use AnyEvent;
use AnyEvent::Socket qw(tcp_server);
use Test::Memory::Cycle ();
use Test::More;
use Test::Builder;

our @EXPORT_OK = qw(start_server set_timeout memory_cycle_ok memory_cycle_exists);

sub start_server {
    my ($port, $accept_cb);
    if(@_ == 1) {
        ($accept_cb) = @_;
    }elsif(@_ == 2) {
        ($port, $accept_cb) = @_;
    }else {
        die "specify ([port], accept_cb)";
    }

    my $cv_server_port = AnyEvent->condvar;
    tcp_server '127.0.0.1', $port, $accept_cb, sub { ## prepare cb
        my ($fh, $host, $port) = @_;
        $cv_server_port->send($port);
    };
    return $cv_server_port;
}

sub set_timeout {
    my ($timeout) = @_;
    $timeout ||= 10;
    my $w;
    $w = AnyEvent->timer(after => $timeout, cb => sub {
        fail("Timeout");
        undef $w;
        exit 2;
    });
}

foreach my $func (qw(memory_cycle_ok memory_cycle_exists)) {
    no strict "refs";
    *{$func} = sub {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        local $SIG{__WARN__} = sub {
            note(shift);
        };
        return &{"Test::Memory::Cycle::$func"}(@_);
    };
}


1;
