#!perl
use AnyEvent;
use lib '../../lib';
use AnyEvent::BitTorrent;
use Net::BitTorrent::Protocol qw[:all];
use Test::More;
use File::Temp;
$|++;
my $torrent = q[t/900_data/kubuntu-active-13.04-desktop-i386.iso.torrent];
my $basedir = File::Temp::tempdir('AB_XXXX', TMPDIR => 1);
chdir '../..' if !-f $torrent;
my $cv = AE::cv;
my $client;
my $to = AE::timer(90, 0, sub { diag 'Timeout'; ok 'Timeout'; $cv->send });
#
$client = AnyEvent::BitTorrent->new(
    basedir      => $basedir,
    path         => $torrent,
    on_hash_pass => sub {
        pass 'Got piece number ' . pop;
        $client->stop;
        $cv->send;
    }
);
#
note 'hashchecking...';
$client->hashcheck();
note 'running client...';
$cv->recv;    # Pulls one full piece and quits
done_testing;
