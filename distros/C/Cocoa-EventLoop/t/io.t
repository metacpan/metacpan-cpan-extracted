use strict;
use warnings;
use Test::More;

use Test::TCP;
use IO::Socket::INET;
use Socket qw/IPPROTO_TCP TCP_NODELAY SOCK_STREAM/;

use Cocoa::EventLoop;

test_tcp(
    client => sub {
        my ($port) = @_;

        my $sock = IO::Socket::INET->new(
            PeerHost => '127.0.0.1',
            PeerPort => $port,
            Proto    => 'tcp',
            Blocking => 0,
        ) or die $!;

        my $end = 0;
        my $io; $io = Cocoa::EventLoop->io(
            fh   => $sock,
            poll => 'w',
            cb   => sub {
                undef $io;

                my $time = time;
                syswrite($sock, $time);

                $io = Cocoa::EventLoop->io(
                    fh   => $sock,
                    poll => 'r',
                    cb   => sub {
                        undef $io;

                        my $r = sysread($sock, my $buf, 256);
                        if ($r) {
                            is $time, $buf, 'echo response ok';
                            $end++;
                        }
                    },
                );
            },
        );

        Cocoa::EventLoop->run_while(0.1) while !$end;
    },
    server => sub {
        my ($port) = @_;

        # simple echo server
        my $sock = IO::Socket::INET->new(
            LocalPort => $port,
            Type      => SOCK_STREAM,
            Blocking  => 0,
            ReuseAddr => 1,
            Listen    => 5,
        ) or die $!;

        my $server = Cocoa::EventLoop->io(
            fh   => fileno($sock),
            poll => 'r',
            cb   => sub {
                my $csock = $sock->accept or return;
                IO::Handle::blocking($csock, 0);
                setsockopt($csock, IPPROTO_TCP, TCP_NODELAY, pack('l', 1)) or die;
                
                my $io; $io = Cocoa::EventLoop->io(
                    fh   => fileno($csock),
                    poll => 'r',
                    cb   => sub {
                        scalar $io; # keeping io ref

                        my $r = sysread($csock, my $buf, 256);
                        if ($r) {
                            syswrite($csock, $buf);
                        }
                    },
                );
            },
        );

        Cocoa::EventLoop->run;        
    },
);

done_testing;
