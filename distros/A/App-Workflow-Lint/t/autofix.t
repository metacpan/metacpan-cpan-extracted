use strict;
use warnings;
use Test::Most;

use_ok('App::Workflow::Lint::Rule::MissingTimeout');

my $rule = new_ok('App::Workflow::Lint::Rule::MissingTimeout');

my $wf = { jobs => { build => {} } };

my @out = $rule->check($wf, { file => 'test.yml' });

is scalar(@out), 1, 'one diagnostic returned';
like $out[0]{message}, qr/missing timeout/, 'message looks right';

done_testing;

