#!perl

use 5.010001;
use strict;
use warnings;
use Test::More;

use FindBin '$RealBin';
use lib "$RealBin/lib";

use Test::CSAF qw(exec_validator_mandatory_test);
use CSAF;

# 6.1.15 Translator

# It MUST be tested that /document/source_lang is present and set if the value translator is used for /document/publisher/category.

# The relevant path for this test is:

#   /document/source_lang

# Fail test:

#  "document": {
#    // ...
#    "publisher": {
#      "category": "translator",
#      "name": "CSAF TC Translator",
#      "namespace": "https://csaf.io/translator"
#    },
#    "title": "Mandatory test: Translator (failing example 1)",
#    // ...
#  }


my $csaf = CSAF->new;

$csaf->document->title('Mandatory test: Translator (failing example 1)');
$csaf->document->category('csaf_security_advisory');
$csaf->document->publisher(
    category  => 'translator',
    name      => 'CSAF TC Translator',
    namespace => 'https://csaf.io/translator'
);

my $tracking = $csaf->document->tracking(
    id                   => 'CSAF:2023-001',
    status               => 'final',
    version              => '1.0.0',
    initial_release_date => 'now',
    current_release_date => 'now'
);

exec_validator_mandatory_test($csaf, '6.1.15');

done_testing;
