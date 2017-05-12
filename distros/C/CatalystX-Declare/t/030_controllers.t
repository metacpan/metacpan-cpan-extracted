#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More;

use aliased 'TestApp::Controller::TestController';

ok +(my $meta = TestController->meta), 'controller has meta';

ok $meta->has_method('ctrl_method'), 'method is available in controller';
ok $meta->has_method('ctrl_action'), 'action method is available in controller';

done_testing;
