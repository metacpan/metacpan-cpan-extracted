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

    my %k;
    $doc->each_key(sub { my ($self, %args) = @_; $k{ "$args{section}_$args{key}" } = $args{raw_value} });
    is_deeply(\%k, {s1_v=>1, s2_v=>2, s1_v2=>2}) or diag explain \%k;

    subtest "opt:early_exit=1" => sub {
        my %k;
        my $n = 0;
        $doc->each_key({early_exit=>1}, sub { my ($self, %args) = @_; $k{ "$args{section}_$args{key}" } = $args{raw_value}; $n++ >= 1 ? 0:1 });
        is_deeply(\%k, {s1_v=>1, s2_v=>2}) or diag explain \%k;
    };
};

DONE_TESTING:
done_testing;
