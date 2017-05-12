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
my $client;
#
$client = AnyEvent::BitTorrent->new(
    basedir      => $basedir,
    path         => $torrent,
    on_hash_pass => sub {
        fail 'Got piece number ' . pop(@_) . ' of ' . $client->piece_count;
    },
    on_hash_fail => sub {
        pass 'Missing piece number '
            . pop(@_) . ' of '
            . $client->piece_count;
    }
);
$client->stop;
#
like $client->peerid, qr[^-AB\d{3}[SU]-.{12}$], 'peerid( )';
is $client->infohash, pack('H*', 'c5588b4606dd1d58e7fb93d8c067e9bf2b50a864'),
    'infohash( )';
is $client->size, 1102970880, 'size( )';
is $client->name, 'kubuntu-active-13.04-desktop-i386.iso', 'name( )';
like $client->reserved, qr[^.{8}$], 'reserved( )';    # Weak test
done_testing
