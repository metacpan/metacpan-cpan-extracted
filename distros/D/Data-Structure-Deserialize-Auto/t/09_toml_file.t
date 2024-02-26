#!/usr/bin/perl
use v5.26;
use warnings;

use Test2::V0;

use Data::Structure::Deserialize::Auto qw(deserialize);

my $filename = 't/data/sample.toml';

my $ds = deserialize($filename);
is($ds->{doe}, 'a deer, a female deer', 'deserialize TOML file');

done_testing;
