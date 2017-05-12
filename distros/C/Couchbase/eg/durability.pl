#!/usr/bin/perl
use strict;
use warnings;
use blib;
use Data::Printer;
use Couchbase::Document;
use Couchbase::Bucket;
use Time::HiRes qw(time);

my $begin;

sub mark_begin($) {
    my $msg = shift;
    $begin = time();
    print "$msg\n";
}
sub mark_end {
    my $now = time();
    my $duration = $now - $begin;
    printf("Duration: %0.4fs\n\n", $duration);
}

my $cb = Couchbase::Bucket->new('couchbase://192.168.72.101/default');
my @docs = map { Couchbase::Document->new("DUR:$_", "VALUE") } (0..100);

mark_begin("Trying one doc at a time..");
# You can either do it one at a time..
$cb->upsert($_, { persist_to => 1, replicate_to => 1 }) for @docs;
map { warn $_->errstr unless $_->is_ok } @docs;
mark_end();

mark_begin("Using a single batch..");
# Or batch them up (per operation) - this has less latency, but uses a bit
# more CPU/network resources
my $batch = $cb->batch();
$batch->upsert($_, { persist_to => 1, replicate_to => 1 }) for @docs;
$batch->wait_all();
map { warn $_->errstr unless $_->is_ok } @docs;
mark_end();

mark_begin("Using two batches");
# Or do two batches; one for durability and one for storage
$batch = $cb->batch;
$batch->upsert($_) for @docs;
$batch->wait_all();
map { warn $_->errstr unless $_->is_ok } @docs;

my $dbatch = $cb->durability_batch( { persist_to => 1, replicate_to => 1 });
$dbatch->endure($_) for @docs;
$dbatch->wait_all;
map { warn $_->errstr unless $_->is_ok } @docs;
mark_end();
