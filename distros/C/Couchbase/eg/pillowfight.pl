#!/usr/bin/perl
use blib;
use strict;
use warnings;
use Time::HiRes qw(time);
use Getopt::Long;
use Couchbase::Bucket;
use Couchbase::Document;

# This file functions like a miniature version of pillowfight

GetOptions(
    'U|connspec=s' => \(my $CONNSTR = "couchbase://localhost/default"),
    'r|ratio=i' => \(my $SET_RATIO = 1),
    'key-size' => \(my $KEY_SIZE = 20),
    'value-size' => \(my $VALUE_SIZE = 32)
);

my $doc = Couchbase::Document->new('K' x $KEY_SIZE, 'V' x $VALUE_SIZE,
                                   { format => COUCHBASE_FMT_RAW });
my $cb = Couchbase::Bucket->new($CONNSTR);
my $begin = time();
my $nops = 0;
$| = 1;

my $meth_set = \&Couchbase::Bucket::upsert;
my $meth_get = \&Couchbase::Bucket::get;

# Store it once
$cb->upsert($doc);
die $doc->errstr unless $doc->is_ok;
my $meth;

while (1) {
    if ($SET_RATIO && rand($SET_RATIO) % $SET_RATIO == 0) {
        $meth = $meth_set;
    } else {
        $meth = $meth_get;
    }

    $meth->($cb, $doc);
    if (++$nops % 1000 == 0) {
        printf("Ops/Sec: %20d\r", $nops / (time()-$begin));
    }
}
