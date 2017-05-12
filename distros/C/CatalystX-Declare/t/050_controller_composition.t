#!/usr/bin/env perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More;

use aliased 'TestApp::Controller::Composed';

ok +(my $meta = Composed->meta), 'controller has meta';

ok $meta->find_method_by_name($_), "method $_ is available in composed controller"
    for qw(
            original_method
            original_action
            inherited_method
            inherited_action
            composed_method
            composed_action
        );

done_testing;
