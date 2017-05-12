#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use 5.010000;
use autodie;
use AnyEvent::IMAP;
use Config::Pit;
use Log::Minimal;
use AnyEvent::IMAP::Envelope;

my $conf = pit_get('damail', require => {
    'imap_server' => 'imap server',
    imap_user => 'user',
    imap_pass => 'pass',
    imap_ssl => 1,
    imap_port => 993,
});

my $imap = AnyEvent::IMAP->new(
    host => $conf->{imap_server},
    user => $conf->{imap_user},
    pass => $conf->{imap_pass},
    ssl  => 1,
    port => 993,
);
$imap->reg_cb(
    connect => sub {
        infof("connected.");
        $imap->login()->cb(sub {
            my ($ok, $line) = shift->recv;
            if ($ok) {
                $imap->capability()->cb(sub {
                    my ($ok, $line) = shift->recv;
                    infof("%s", ddf($line));
                });
                $imap->folders()->cb(sub {
                    my ($ok, $folders) = shift->recv;
                    if ($ok) {
                        $imap->status('INBOX')->cb(sub {
                            my ($ok, $status) = shift->recv;
                            infof("INBOX status: %s", ddf($status));
                        });
                        $imap->status_multi($folders)->cb(sub {
                            my ($ok, $statuses) = shift->recv;
                            infof("status_multi: %s", ddf($statuses));
                        });
                        $imap->select('INBOX')->cb(sub {
                            my ($ok, $ret) = shift->recv;
                            if ($ok) {
                                infof("selected: %s", ddf($ret));
                                $imap->fetch('1:5 (UID FLAGS INTERNALDATE RFC822.SIZE ENVELOPE BODYSTRUCTURE)')->cb(sub {
                                    my ($ok, $ret) = shift->recv;
                                    infof("summaries: %s ****************", $ok);
                                    for my $summary (@$ret) {
                                        $summary->{ENVELOPE} = AnyEvent::IMAP::Envelope->new(delete $summary->{ENVELOPE});
                                        infof("%s", ddf($summary));
                                    }
                                });
                                $imap->expunge()->cb(sub {
                                    my ($ok, $ret)= shift->recv;
                                    infof("expunge: %s", $ok);
                                });
                                $imap->create_folder('TEST');
                            }
                        });
                    }
                    infof('%s', ddf($line));
                });
            }
        });
    },
    send => sub {
        infof("SEND: %s", $_[1]);
    },
    recv => sub {
        infof("RECV: %s", $_[1]);
    },
    disconnect => sub {
        infof("disconnect: %s", $_[1]);
        $imap->connect();
    },
);
my ($ok, $res) = $imap->connect()->recv();
unless ($ok) {
    die $res;
}

# send ping
my $timer = AE::timer(30, 20*60, sub {
    $imap->noop();
});

AE::cv()->recv;

