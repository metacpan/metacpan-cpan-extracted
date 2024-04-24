#!perl

use 5.010001;
use strict;
use warnings;
use Test::More;

use FindBin '$RealBin';
use lib "$RealBin/lib";

use Test::CSAF qw(exec_validator_mandatory_test);
use CSAF;

# 6.1.17 Document Status Draft

# It MUST be tested that document status is draft if the document version is 0 or 0.y.z or contains the pre-release part.

# The relevant path for this test is:

#   /document/tracking/status

# Fail test:

#     "tracking": {
#       // ...
#       "status": "final",
#       "version": "0.9.5"
#     }

my $csaf = CSAF->new;

$csaf->document->title('Base CSAF Document');
$csaf->document->category('csaf_security_advisory');
$csaf->document->publisher(category => 'vendor', name => 'CSAF', namespace => 'https://csaf.io');

my $tracking = $csaf->document->tracking(
    id                   => 'CSAF:2023-001',
    status               => 'final',
    version              => '0.9.5',
    initial_release_date => 'now',
    current_release_date => 'now'
);

exec_validator_mandatory_test($csaf, '6.1.17');

done_testing;
