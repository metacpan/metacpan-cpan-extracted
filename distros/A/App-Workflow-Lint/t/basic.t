use strict;
use warnings;
use Test::Most;

use App::Workflow::Lint;

my $lint = App::Workflow::Lint->new;

ok($lint, 'constructor returns an object');

done_testing;

