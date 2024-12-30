#!perl

use v5.14;
use warnings;

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

use Test2::V0;

eval "use Test::CVE";

plan skip_all => "Test::CVE not installed" if $@;

my $cve = Test::CVE->new (
   verbose  => 0,
   deps     => 1,
   perl     => 0,
   make_pl  => "Makefile.PL",
);

$cve->test;

is [ $cve->cve ], [], "no CVEs"
  or diag( $cve->report( width => $ENV{COLUMNS} || 80 ) );

done_testing;
