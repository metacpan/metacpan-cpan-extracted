#!/usr/bin/perl
use v5.26;
use warnings;

use Test2::V0;

use Data::Structure::Deserialize::Auto qw(deserialize);

my $str = <<'END';
---
a: 1
b: 2
c: 3
END
my $ds = deserialize($str);
is($ds->{b}, 2, 'deserialize yaml string');

done_testing;
