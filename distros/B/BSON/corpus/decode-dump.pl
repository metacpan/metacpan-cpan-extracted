#!/usr/bin/env perl
use v5.10;
use strict;
use warnings;

use Data::Dumper qw/Dumper/;
use BSON qw/decode/;
use MongoDB::BSON;
use MongoDB::OID;
use MongoDB::BSON::Binary;

my $codec = MongoDB::BSON->new;

local $Data::Dumper::Indent = 0;
local $Data::Dumper::Useqq = 1;
local $Data::Dumper::Quotekeys = 1;

my $from_cli = @ARGV;

while (1) {
    my $s = $from_cli ? shift(@ARGV) : <STDIN>;
    last unless defined $s;

    chomp $s;
    $s =~ tr[ ][]s;
    $s = pack("H*",$s);

    my $pp = eval { decode($s) };
    warn "PP error: $@\n" if $@;
    $pp = Dumper($pp);

    my $xs = eval { $codec->decode_one($s) };
    warn "XS error: $@\n" if $@;
    $xs = Dumper($xs);

    say "PP\n$pp\n";
    say "XS\n$xs\n";
    say "PP and XS are " . ($pp eq $xs ? "the same" : "NOT the same");
}
