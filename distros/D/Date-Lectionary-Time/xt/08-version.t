use v5.22;
use strict;
use warnings;
use Test::More;
use Test::Version 1.001001 qw( version_all_ok ), {
    is_strict   => 0,
    has_version => 1,
    consistent  => 1,
  };
 
version_all_ok();
 
done_testing();