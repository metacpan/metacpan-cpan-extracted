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

    my %k;
    my $n = 0;
    $doc->each_section(sub { my ($self, %args) = @_; $k{ "$args{section}" } = $n++ });
    is_deeply(\%k, {s1=>2, s2=>1, s3=>3}) or diag explain \%k;

    subtest "opt:early_exit=1" => sub {
        my %k;
        my $n = 0;
        $doc->each_section({early_exit=>1}, sub { my ($self, %args) = @_; $k{ "$args{section}" } = $n; $n++ >= 1 ? 0:1 });
        is_deeply(\%k, {s1=>0, s2=>1}) or diag explain \%k;
    };
};

DONE_TESTING:
done_testing;
