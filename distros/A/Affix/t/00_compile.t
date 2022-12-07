use strict;
use Test::More 0.98;
use lib '../lib', 'lib';
use_ok $_ for qw[Dyn::Call Dyn::Callback Dyn::Load Dyn Affix];
done_testing;
