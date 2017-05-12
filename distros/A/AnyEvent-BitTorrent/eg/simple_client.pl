#!perl
use lib '../lib';
use AnyEvent::BitTorrent;
use Net::BitTorrent::Protocol qw[:all];
$|++;

#
my $client = AnyEvent::BitTorrent->new(
                                  path         => 'a/legal.torrent',
                                  on_hash_pass => sub { warn 'PASS: ' . pop },
                                  on_hash_fail => sub { warn 'FAIL: ' . pop }
);
$client->hashcheck();
AE::cv->recv;
