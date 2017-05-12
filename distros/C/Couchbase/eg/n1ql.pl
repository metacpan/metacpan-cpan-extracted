#!/usr/bin/env perl
use strict;
use warnings;
use Couchbase::Bucket;
use Data::Printer;
use JSON;

my $bkt = Couchbase::Bucket->new('couchbase://localhost:12000/travel');
my $doc = Couchbase::Document->new('landmark_15433');

binmode(STDOUT, ':utf8');

my $rv = $bkt->query_slurp(
    'CREATE PRIMARY INDEX ON travel'
);
warn $rv->errstr unless $rv->is_ok;

my $iter = $bkt->query_iterator(
        'SELECT *, META(travel).id FROM travel ' .
        'WHERE travel.country = $country LIMIT 50',
        { country => "Ecuador" }
    );
while ((my @rows = $iter->next)) {
    p $_ for @rows;
}
die $iter->errstr unless $iter->is_ok;
p $iter;
