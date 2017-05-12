#!perl -T

use strict;
use warnings;
use Test::More;

plan (skip_all => "Author tests not required for installation") unless ($ENV{RELEASE_TESTING});

plan tests => 3;

SKIP: {
  skip "Test::CheckManifest 0.9 required", 1 unless eval "use Test::CheckManifest 0.9";
  ok_manifest();
}

SKIP: {
  skip "Test::Pod 1.22 required", 1 unless eval "use Test::Pod 1.22";
  all_pod_files_ok();
}

SKIP: {
  skip "Test::Pod::Coverage 1.08 required", 1 unless eval "use Test::Pod::Coverage 1.08";
  all_pod_coverage_ok();
}
