#!perl

use 5.010001;
use strict;
use warnings;
use Test::More;

use FindBin '$RealBin';
use lib "$RealBin/lib";

use Test::CSAF qw(exec_validator_mandatory_test);
use CSAF;

# 6.1.27.11 Vulnerabilities

# It MUST be tested that the element /vulnerabilities exists.

# The relevant values for /document/category are:

#   csaf_security_advisory
#   csaf_vex

# The relevant path for this test is:

#   /vulnerabilities

# Fail test:

#  {
#    "document": {
#      // ...
#    },
#    "product_tree": [
#      // ...
#    ]
#  }

my $csaf = CSAF->new;

$csaf->document->title('Mandatory test: 6.1.27.11');
$csaf->document->publisher(category => 'vendor', name => 'CSAF', namespace => 'https://csaf.io');

my $tracking = $csaf->document->tracking(
    id                   => 'CSAF:2023-001',
    status               => 'final',
    version              => '1.0.0',
    initial_release_date => 'now',
    current_release_date => 'now'
);

foreach my $category (qw(csaf_security_advisory csaf_vex)) {

    $csaf->document->category($category);

    exec_validator_mandatory_test($csaf, '6.1.27.11');

}

done_testing;
