#!perl

use 5.010;
use strict;
use warnings;

#use Test::Config::IOD qw(test_modify_doc);
use Config::IOD;
use Test::More 0.98;

subtest "list_keys" => sub {
    my $iod = <<'_';
[s1]
v=1
w=1
v=2
[s2]
[s1]
x=1
_
    my $ciod = Config::IOD->new;
    my $doc = $ciod->read_string($iod);
    is_deeply([$doc->list_keys('s1')], [qw/v w v x/]);
    is_deeply([$doc->list_keys({unique=>1}, 's1')], [qw/v w x/]);
};

DONE_TESTING:
done_testing;
