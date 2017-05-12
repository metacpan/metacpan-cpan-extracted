#!/usr/env perl

# $Id: t0.t 13 2009-12-04 11:16:01Z stro $

use strict;
use warnings;

BEGIN {
	use Test;
	plan('tests' => 1);
}

require CGI::Application::Plugin::DevPopup::Params; # require, no use -- import wouldn't work this way

ok(1); # sanity check and other modules skipping workaround

