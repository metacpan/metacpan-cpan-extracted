#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More;

use aliased 'TestApp::TestRole';

ok +(my $meta = TestRole->meta), 'controller role has meta';

ok $meta->has_method('something_from_the_role'), 'method is available in role';
ok $meta->has_method('action_from_ctrl_role'), 'action method is available in role';

done_testing;
