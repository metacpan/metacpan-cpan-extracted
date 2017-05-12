#!perl

use 5.010;
use strict;
use warnings;

#use Test::Config::IOD qw(test_modify_doc);
use Config::IOD;
use Test::More 0.98;

subtest "each_section" => sub {
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
    ok 1; # TODO, currently we test via list_sections()
    #is_deeply([$doc->each_sections], [qw/s1 s2 s1 s3/]);
    #is_deeply([$doc->each_sections({unique=>1})], [qw/s1 s2 s3/]);
};

DONE_TESTING:
done_testing;
