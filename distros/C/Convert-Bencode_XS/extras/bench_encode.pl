#!/usr/bin/perl

use strict;
use Benchmark qw(cmpthese);
use Convert::Bencode_XS;
use Convert::Bencode;

our ($stuff, $data);

#we prepare in $stuff a typical server response bencoded string

$stuff = {
    interval    =>  180,
    peers       =>  [ {
        peer_id =>  'ABCDEFGHIJKLMNOPQRST',
        ip      =>  '192.168.1.0',
        port    =>  6881
    }, ],
};

for (1..49) {
    push @{ $stuff->{peers} }, $stuff->{peers}[0];
}

cmpthese(-5, {
    Bencode_XS  =>  sub {$data = Convert::Bencode_XS::bencode($stuff)},
    Bencode     =>  sub {$data = Convert::Bencode::bencode($stuff)},
});



