#!/usr/bin/env perl


use v5.36;

use strict;
use warnings;
use Test2::V0;

# Test that all Concierge::Auth modules can be loaded

use Concierge::Auth;
pass('Concierge::Auth Module loaded successfully');

use Concierge::Auth::Base;
pass('Concierge::Auth::Base Module loaded successfully');

use Concierge::Auth::Pwd;
pass('Concierge::Auth::Pwd Module loaded successfully');

use Concierge::Auth::Generators;
pass('Concierge::Auth::Generators Module loaded successfully');

done_testing;
