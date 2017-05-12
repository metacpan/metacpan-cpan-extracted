#!/usr/bin/env perl
use v5.10;
use strict;
use warnings;

use Data::Dumper qw/Dumper/;
use BSON qw/decode encode/;
use MongoDB::BSON;

my $codec = MongoDB::BSON->new;

my $from_cli = @ARGV;

while (1) {
    my $s = $from_cli ? shift(@ARGV) : <STDIN>;
    last unless defined $s;

    chomp $s;
    $s = eval($s);
    if ( $@ ) {
        warn "Eval error: $@\n";
        next;
    }
    unless ( ref($s) eq 'HASH' ) {
        warn "Not a HASH\n";
        next;
    }

    my $pp = eval { encode($s) };
    warn "PP error: $@\n" if $@;

    my $xs = eval { $codec->encode_one($s) };
    warn "XS error: $@\n" if $@;

    say "PP\n" . unpack("H*",$pp) . "\n";
    say "XS\n" . unpack("H*",$xs) . "\n";
    say "PP and XS are " . ($pp eq $xs ? "the same" : "NOT the same");
}
