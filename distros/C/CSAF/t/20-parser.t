#!perl

use strict;
use warnings;

use Test::More;
use FindBin '$RealBin';

use CSAF::Parser;

subtest 'Parse file' => sub {

    my $validation_errors = 0;

    my $parser = CSAF::Parser->new(file => "$RealBin/examples/cisco-sa-20180328-smi2.json");
    my $csaf   = $parser->parse;

    isa_ok($csaf, 'CSAF');

    is(
        $csaf->document->title,
        'Cisco IOS and IOS XE Software Smart Install Remote Code Execution Vulnerability',
        'Test title'
    );

    is($csaf->document->category, 'Cisco Security Advisory', 'Test category');

};

subtest 'Parse string' => sub {

    my $parser = CSAF::Parser->new(content => <<JSON);
{
  "document": {
    "category": "csaf_base",
    "csaf_version": "2.0",
    "publisher": {
      "category": "other",
      "name": "OASIS CSAF TC",
      "namespace": "https://csaf.io"
    },
    "title": "Template for generating CSAF files for Validator examples",
    "tracking": {
      "current_release_date": "2021-07-21T10:00:00.000Z",
      "id": "OASIS_CSAF_TC-CSAF_2.0-2021-TEMPLATE",
      "initial_release_date": "2021-07-21T10:00:00.000Z",
      "revision_history": [
        {
          "date": "2021-07-21T10:00:00.000Z",
          "number": "1",
          "summary": "Initial version."
        }
      ],
      "status": "final",
      "version": "1"
    }
  }
}
JSON

    my $csaf = $parser->parse;

    isa_ok($csaf, 'CSAF');

    is($csaf->document->title, 'Template for generating CSAF files for Validator examples', 'Test title');

    is($csaf->document->category, 'csaf_base', 'Test category');

};

done_testing();
