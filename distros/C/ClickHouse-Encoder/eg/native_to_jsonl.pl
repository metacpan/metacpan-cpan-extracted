#!/usr/bin/env perl
# native_to_jsonl.pl - convert a `format native` byte stream into
# newline-delimited JSON on stdout. Useful for piping CH select
# results into tools that can't read Native (jq, awk, log shippers).
#
# Usage:
#   curl 'http://src/?query=select+*+from+t+format+native' \
#     | native_to_jsonl.pl > t.ndjson
#
# Reads incrementally; memory stays bounded by one block at a time.
use strict;
use warnings;
use ClickHouse::Encoder;

# Prefer XS for speed; fall back to core JSON::PP.
my $encode_json = do {
    if (eval { require Cpanel::JSON::XS; 1 }) {
        my $j = Cpanel::JSON::XS->new->utf8->canonical;
        sub { $j->encode($_[0]) };
    } elsif (eval { require JSON::XS; 1 }) {
        my $j = JSON::XS->new->utf8->canonical;
        sub { $j->encode($_[0]) };
    } else {
        require JSON::PP;
        my $j = JSON::PP->new->utf8->canonical;
        sub { $j->encode($_[0]) };
    }
};

binmode STDIN;
binmode STDOUT;

ClickHouse::Encoder->decode_stream(\*STDIN, sub {
    my $block = shift;
    my @names = map $_->{name}, @{ $block->{columns} };
    for my $r (0 .. $block->{nrows} - 1) {
        my %row;
        for my $c (0 .. $#names) {
            $row{ $names[$c] } = $block->{columns}[$c]{values}[$r];
        }
        print $encode_json->(\%row), "\n";
    }
});
