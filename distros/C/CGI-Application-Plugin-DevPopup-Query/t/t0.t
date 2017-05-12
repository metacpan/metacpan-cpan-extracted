#!/usr/env perl

# $Id: t0.t 30 2011-06-10 04:48:54Z stro $

use strict;
use warnings;

BEGIN {
    use Test;
    plan('tests' => 1);
}

require CGI::Application::Plugin::DevPopup::Query; # require, no use -- import wouldn't work this way

ok(1); # sanity check and other modules skipping workaround

