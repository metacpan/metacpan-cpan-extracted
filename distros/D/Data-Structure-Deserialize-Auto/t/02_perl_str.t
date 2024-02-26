#!/usr/bin/perl
use v5.26;
use warnings;

use Test2::V0;

use Data::Structure::Deserialize::Auto qw(deserialize);

my $str = "{
  a => 1,
  b => 2,
  c => 3
}";
my $ds = deserialize($str);
is($ds->{b}, 2, 'deserialize perl string');

use Data::Dumper;
$Data::Dumper::Terse = 1;
my $data = {
  a => 1,
  b => 2,
  c => 3,
};
$str = Dumper($data);
$ds  = deserialize($str);
is($ds->{c}, 3, 'deserialize Data::Dumper string');

done_testing;
