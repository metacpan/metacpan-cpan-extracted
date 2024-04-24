#!perl

use 5.010001;
use strict;
use warnings;
use Test::More;

use FindBin '$RealBin';
use lib "$RealBin/lib";

use Test::CSAF qw(base_csaf_security_advisory exec_validator_optional_test);
use CSAF::Validator::OptionalTests;

# 6.2.14 Use of Private Language

# For each element of type /$defs/language_t it MUST be tested that the language code does not contain subtags reserved for private use.

# The relevant paths for this test are:

#   /document/lang
#   /document/source_lang

# Fail test:
#  "document": {
#    // ...
#    "lang": "qtx",
#    // ...
#  }

#   The language code qtx is reserved for private use.
#   A tool MAY remove such subtag as a quick fix.

my $csaf = base_csaf_security_advisory();

$csaf->document->lang('qtx');
$csaf->document->source_lang('qtx');

exec_validator_optional_test($csaf, '6.2.14');

done_testing;
