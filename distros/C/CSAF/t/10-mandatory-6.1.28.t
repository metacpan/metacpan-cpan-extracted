#!perl

use 5.010001;
use strict;
use warnings;
use Test::More;

use FindBin '$RealBin';
use lib "$RealBin/lib";

use Test::CSAF qw(exec_validator_mandatory_test);
use CSAF;

# 6.1.28 Translation

# It MUST be tested that the given source language and document language are not the same.

# The relevant path for this test is:

#  /document/lang
#  /document/source_lang

# Fail test:

#  "document": {
#    // ...
#    "lang": "en-US",
#    // ...
#    "source_lang": "en-US",
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

$csaf->document->lang('en-US');
$csaf->document->source_lang('en-US');

my $tracking = $csaf->document->tracking(
    id                   => 'CSAF:2023-001',
    status               => 'final',
    version              => '1.0.0',
    initial_release_date => 'now',
    current_release_date => 'now'
);

exec_validator_mandatory_test($csaf, '6.1.28');

done_testing;
