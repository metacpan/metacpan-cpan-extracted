use strict;
use warnings;
use Test::More;
use AnyEvent::Impl::Perl;
use lib '../lib';
use AnyEvent::Handle::Throttle;
use Socket;
$|++;
my $cv = AnyEvent->condvar;
my ($read, $write, $onekchunks, $dat);
my $now = AE::now;
my $len = 0;
socketpair my $rd, my $wr, AF_UNIX, SOCK_STREAM, PF_UNSPEC;
my $wr_ae = AnyEvent::Handle::Throttle->new(
    fh     => $wr,
    on_eof => sub {
        note 'writer got EOF';
        $cv->broadcast;
    }
);
my $rd_ae = AnyEvent::Handle::Throttle->new(
    download_limit => 1024,
    fh             => $rd,
    on_eof         => sub {
        note 'reader got EOF';
        $cv->broadcast;
    },
    on_read => sub {
        my ($h) = @_;
        if ($onekchunks++ < 5) {
            my $this_read = length($h->rbuf) - $len;
            is $this_read, 1024,
                sprintf 'Read %s more bytes into rbuf (%d bytes total)',
                $this_read, length $h->rbuf;
            note sprintf '...%fs later', AE::now- $now;
            $now = AE::now;
            $len = length $h->rbuf;
        }
        else {
            $h->push_read(
                chunk => 5132,
                sub {
                    my ($rd_ae, $data) = @_;
                    $dat = substr $data, 0, 2;
                    $dat .= substr $data, -5;
                    is(++$read, 1, 'first read chunk');
                    note sprintf '...%fs later', AE::now- $now;
                    $now = AE::now;
                    my $n = 5;
                    $wr_ae->push_write('A' x 5000);
                    $wr_ae->on_drain(
                        sub {
                            my ($wr_ae) = @_;
                            $wr_ae->on_drain;
                            is(++$write, 4, 'fourth write');
                        }
                    );
                    $rd_ae->push_read(
                        chunk => 5000,
                        sub {
                            is(++$read, 2, 'second read chunk');
                            note sprintf '...%fs later', AE::now- $now;
                            $now = AE::now;
                            $cv->broadcast;
                        }
                    );
                    1;
                }
            );
        }
    }
);
$wr_ae->push_write('A' x 5000);
$wr_ae->push_write('X' x 130);
$wr_ae->on_drain(
    sub {
        my ($wr_ae) = @_;
        $wr_ae->on_drain;
        is(++$write, 1, 'first write');
        $wr_ae->push_write('Y');
        $wr_ae->on_drain(
            sub {
                my ($wr_ae) = @_;
                $wr_ae->upload_limit(512);
                $wr_ae->on_drain;
                is(++$write, 2, 'second write');
                $wr_ae->push_write('Z');
                $wr_ae->on_drain(
                    sub {
                        my ($wr_ae) = @_;
                        $wr_ae->on_drain;
                        is(++$write, 3, 'third write');
                    }
                );
            }
        );
    }
);
$cv->recv;
ok($dat eq 'AAXXXYZ', 'received data') || note '$dat was: ' . $dat;

#
ok !$rd_ae->upload_total, 'reader uploaded nothing';
is $rd_ae->global_upload_total, 10132, 'reader says uploaded is 10132 bytes';
is $rd_ae->download_total, 10132,
    'reader claims to have downloaded 10132 bytes';
is $rd_ae->global_download_total, 10132,
    'reader claims global download was 10132 bytes';
is $wr_ae->upload_total,        10132, 'writer says it uploaded 10132 bytes';
is $wr_ae->global_upload_total, 10132, 'writer says uploaded is 10132 bytes';
ok !$wr_ae->download_total, 'writer claims to have downloaded nothing';
is $wr_ae->global_download_total, 10132,
    'writer claims global download was 10132 bytes';

#
done_testing;
