use warnings;
use strict;

use Test::More;
use File::Find;

require DBIO;
unless ( DBIO::Optional::Dependencies->req_ok_for ('test_pod') ) {
  my $missing = DBIO::Optional::Dependencies->req_missing_for ('test_pod');
  $ENV{RELEASE_TESTING}
    ? die ("Failed to load release-testing module requirements: $missing")
    : plan skip_all => "Test needs: $missing"
}

# this has already been required but leave it here for CPANTS static analysis
require Test::Pod;

# PodWeaver processes custom directives (=method, =attr) and adds =encoding
# at build time. When running raw (prove -l), Test::Pod reports errors for
# these — skip files that need PodWeaver processing.

my @dirs = ('lib');

my @files;
find({ wanted => sub {
  return unless -f $_ && /\.(?:pm|pod)$/i;
  push @files, $_;
}, no_chdir => 1 }, @dirs);

for my $file (sort @files) {
  my $data = do { local (@ARGV, $/) = $file; <> };

  # skip files using PodWeaver directives (processed at build time)
  if ($data =~ /^=(?:method|attr|func)\b/m) {
    SKIP: { skip "$file uses PodWeaver directives (test via dzil test)", 1 }
    next;
  }

  # skip files with no POD at all (internal modules)
  if ($data !~ /^=(head|pod|over|item|begin|end|for|encoding|cut)\b/m) {
    SKIP: { skip "$file has no POD", 1 }
    next;
  }

  Test::Pod::pod_file_ok($file);
}

done_testing;
