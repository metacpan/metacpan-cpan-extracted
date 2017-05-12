#!perl

use 5.010;
use strict;
use warnings;

#use Test::Config::IOD qw(test_modify_doc);
use Config::IOD;
use Test::More 0.98;

subtest "each_key" => sub {
    my $iod = <<'_';
[s1]
v=1
[s2]
v=2
[s1]
v2=2
[s3]
_
    my $ciod = Config::IOD->new;
    my $doc = $ciod->read_string($iod);
    ok 1; # TODO
};

DONE_TESTING:
done_testing;
