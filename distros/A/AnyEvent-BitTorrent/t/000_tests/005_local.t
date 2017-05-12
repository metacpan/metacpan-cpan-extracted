#!perl
use strict;
use warnings;
use AnyEvent;
use lib '../../lib';
use AnyEvent::BitTorrent;
#use Net::BitTorrent::Protocol qw[:all];
use Test::More;
use File::Temp;
$|++;
my $torrent = q[t/900_data/kubuntu-active-13.04-desktop-i386.iso.torrent];
chdir '../..' if !-f $torrent;
require t::800_utils::Tracker::HTTP;
my $cv = AE::cv;
my $to = AE::timer(90, 0, sub { diag 'Timeout'; ok 'Timeout'; $cv->send });

#
my $tracker =
    t::800_utils::Tracker::HTTP->new(host     => '127.0.0.1',
                                     interval => 15
    );
note 'HTTP tracker @ http://'
    . $tracker->host . ':'
    . $tracker->port
    . '/announce.pl';

#
 my ($client, $peer);
 #
$client = AnyEvent::BitTorrent->new(
    basedir      => File::Temp::tempdir('AB_XXXX', TMPDIR => 1),
    path         => $torrent,
    on_hash_pass => sub {
        pass 'Got piece number ' . pop(@_) . ' in client';
        #$client->stop;
        #$cv->send;
    }
);
#
$peer = AnyEvent::BitTorrent->new(
    basedir      => File::Temp::tempdir('AB_XXXX', TMPDIR => 1),
    path         => $torrent,
    on_hash_pass => sub {
        pass 'Got piece number ' . pop(@_) . ' in peer';
        $client->stop;
        $cv->send;
    }
);
#
for my $p ($client, $peer) {
$p->hashcheck();
# add local tracker
push @{$p->trackers}, {
        urls => [
            'http://' . $tracker->host . ':' . $tracker->port . '/announce.pl'
        ],
        complete   => 0,
        incomplete => 0,
        peers      => '',
        ticker     => AE::timer(
            1,
            rand(15) + 5,
            sub {
                return if $p->state eq 'stopped';
                $p->announce();
                note 'Announced from ' . $p->peerid
            }
        ),
        failures => 0
    };}
# remove original tracker

shift @{$peer->trackers};

#
note 'running client...';
$cv->recv;    # Pulls one full piece and quits
done_testing;
