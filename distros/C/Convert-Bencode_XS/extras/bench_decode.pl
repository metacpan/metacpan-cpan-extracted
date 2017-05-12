#!/usr/bin/perl

use strict;
use Benchmark qw(cmpthese);
use Convert::Bencode_XS;
use Convert::Bencode;

if (-t and not @ARGV) {
    print "Usage: $0 file.torrent\n";
    exit;
}

our $data = do {local $/; <>};

our $result;

cmpthese(-10, {
    Bencode_XS  =>  sub {$result = Convert::Bencode_XS::bdecode($data)},
    Bencode     =>  sub {$result = Convert::Bencode::bdecode($data)},
});

