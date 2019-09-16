#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";

BEGIN {
    use Test::More;
    eval { require Digest::HMAC_SHA1 };
    if ($@) {
	diag("party.t skipped: Can't run without Digest::HMAC_SHA1");
	done_testing;
	exit;
    }
}

use_ok ('Digest::HMAC_SHA1', qw/hmac_sha1_hex/);
use_ok('Crypt::IDA::Algorithm');

#use v5.20;

# Example from top of Crypt::IDA::Algorithm page turned into a test

# Make cryptographically secure ticket for entry to a party
my $secret = 'Not just any Tom, Dick and Harry';
my $ticket = 'Admit Tom, Dick /and/ Harry to the party together';
my $signed = "$ticket:" . hmac_sha1_hex($ticket,$secret);

# Algorithm works on full matrix columns, so must pad the message
$signed .= "\0" while length($signed) % 3;

# Turn the signed ticket into three shares
my $s = Crypt::IDA::Algorithm->splitter(k=>3, key=>[1..6]);
$s->fill_stream($signed);
$s->split_stream;
my @tickets = map { $s->empty_substream($_) } (0..2);

is(length($tickets[0]), length($signed)/3, "Share 0 is 1/3 length of msg");
is(length($tickets[1]), length($signed)/3, "Share 1 is 1/3 length of msg");
is(length($tickets[2]), length($signed)/3, "Share 2 is 1/3 length of msg");

# At the party, Tom, Dick and Harry present shares to be combined
my $c = Crypt::IDA::Algorithm->combiner(k=>3, key=>[1..6], 
					sharelist=>[0..2]);
$c->fill_substream($_, $tickets[$_]) foreach (0..2); # same order
$c->combine_streams;
my $got = $c->empty_stream;

is(length($got),length($signed), "combine gave back same length msg");

# Check the recovered ticket
$got =~ /^(.*):(.*)\0*$/;
my ($msg, $sig) = ($1,$2);
ok(defined($msg), "got <msg>:* part of ticket");
ok(defined($sig), "got *:<sig> part of ticket");

is($sig, hmac_sha1_hex($msg,$secret), "signature hash matched");
is($msg, $ticket, "text of ticket matches original");

done_testing;
