#!/usr/bin/env perl
# CVE-Client: CLI-based client / toolbox for CVE.org
# Copyright © 2021-2023 CVE-Client Authors <https://hacktivis.me/git/cve-client/>
# SPDX-License-Identifier: AGPL-3.0-only
use strict;
use utf8;

use Test::More tests => 2;
use Test::Output;

use JSON::MaybeXS;

use App::CveClient qw(print_cve);

my $json = JSON::MaybeXS->new(utf8 => 1);

open(CVE_IN,  '<', 't/cve_schema50.CVE-2022-24903.json') or die "$!";
open(CVE_OUT, '<', 't/cve_schema50.CVE-2022-24903.txt')  or die "$!";

my $object = $json->decode(<CVE_IN>) or die "$!";

# Read whole files
undef $/;

output_is { print_cve($object, 'CVE-2022-24903') } <CVE_OUT>, '',
  'Test printing CVE-2022-24903';

output_is { print_cve($object, 'CVE-222-24903') } <CVE_OUT>,
  "Warning: Got <CVE-2022-24903> instead of <CVE-222-24903>\n",
  'XTest printing CVE-2022-24903 with cve_id being CVE-222-24903';

close(CVE_IN);
close(CVE_OUT);

# TODO: Figure out how to test fails properly
#
#my $nx_object = $json->decode('{"error":"CVE_RECORD_DNE","message":"The cve record for the cve id does not exist."}');
#
#output_is { print_cve($nx_object, 'CVE-1995-24903') } '', 'Error (CVE_RECORD_DNE): The cve record for the cve id does not exist.', 'Test printing non-existant CVE-1995-24903';

done_testing;
