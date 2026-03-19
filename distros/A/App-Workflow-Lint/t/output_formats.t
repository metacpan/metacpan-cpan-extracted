use strict;
use warnings;
use Test::Most;

use_ok('App::Workflow::Lint::Formatter');

my $diags = [
    {
        rule    => 'missing-timeout',
        level   => 'warning',
        message => 'Job build is missing timeout-minutes',
        path    => '/jobs/build',
        file    => 'test.yml',
    }
];

# JSON
my $json = App::Workflow::Lint::Formatter->format('json', $diags);
like $json, qr/"missing-timeout"/, 'JSON contains rule id';

# SARIF
my $sarif = App::Workflow::Lint::Formatter->format('sarif', $diags);
like $sarif, qr/"version"\s*:\s*"2\.1\.0"/, 'SARIF version present';
like $sarif, qr/"ruleId"\s*:\s*"missing-timeout"/, 'SARIF contains rule id';

done_testing;
