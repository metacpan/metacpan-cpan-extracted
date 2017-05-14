#!perl -T

use Test::More;

BEGIN {
  my $tests = 0;

  foreach (qw/Conclave::OTK Conclave::OTK::Queries Conclave::OTK::Queries::OWL Conclave::OTK::Backend Conclave::OTK::Backend::File/) {
    use_ok($_) || print "$_ failed to load!\n";
    $tests++;
  }

  done_testing($tests);
}

