use strict;
use warnings;
use Test::More;


unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation." );
}


eval q[use Test::Version 1.001001 qw( version_all_ok ), {
    is_strict   => 0,
    has_version => 1,
    consistent  => 1,
  };
];
plan skip_all => "Test::Version required for testing version numbers"
    if $@;

# test blib or lib by default
version_all_ok();

done_testing;
