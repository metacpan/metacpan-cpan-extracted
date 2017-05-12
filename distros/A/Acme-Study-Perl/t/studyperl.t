#!perl -T

use strict;
use warnings;
use Test::More qw(no_plan);
use Acme::Study::Perl qw(studyperl);

SKIP: {
    diag("no tests in this file, only diagnostics");
    skip;
}

diag("\n");
my @tests =
    (
     [q{'123456789123456789.2' <=> '123456789123456790'},
      "native big math float/int"],
     [q{'123456789123456789.2' <=> '123456789123456790.0'},
      "native big math float/float"],
     [q{'123456789123456789' <=> '123456789123456790'},
      "native big math int/int 18"],
     [q{'123456789123456789123456789123456789' <=> '123456789123456789123456789123456790'},
      "native big math int/int 36"],
     [q{sqrt(-1e-309)},
      "negative square root"],
    );
for my $t (@tests) {
    studyperl(@$t);
}

