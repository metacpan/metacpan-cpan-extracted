use strict;
use warnings;
use Test::More;
BEGIN {
  plan skip_all => 'test requires Test::MinimumVersion'
    unless eval q{ use Test::MinimumVersion; 1 };
}

plan tests => 2;

subtest all => sub {
  all_minimum_version_ok '5.010';
};

subtest server => sub {
  minimum_version_ok 'lib/Clustericious/Admin/Server.pm', '5.006';
};
