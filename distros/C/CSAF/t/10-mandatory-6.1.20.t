#!perl

use 5.010001;
use strict;
use warnings;
use Test::More;

use FindBin '$RealBin';
use lib "$RealBin/lib";

use Test::CSAF qw(exec_validator_mandatory_test);
use CSAF;

# 6.1.20 Non-draft Document Version

# It MUST be tested that document version does not contain a pre-release part if the document status is final or interim.

# The relevant path for this test is:

#   /document/tracking/version

# Fail test:

#     "tracking": {
#       // ...
#       "status": "interim",
#       "version": "1.0.0-alpha"
#     }

foreach my $status (qw(interim final)) {

    my $csaf = CSAF->new;

    $csaf->document->title('Base CSAF Document');
    $csaf->document->category('csaf_security_advisory');
    $csaf->document->publisher(category => 'vendor', name => 'CSAF', namespace => 'https://csaf.io');

    my $tracking = $csaf->document->tracking(
        id                   => 'CSAF:2023-001',
        status               => $status,
        version              => '1.0.0-alpha',
        initial_release_date => 'now',
        current_release_date => 'now'
    );

    exec_validator_mandatory_test($csaf, '6.1.20');

}

done_testing;
