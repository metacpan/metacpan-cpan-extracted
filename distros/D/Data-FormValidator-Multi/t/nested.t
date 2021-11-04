#!/usr/bin/env perl
use warnings;
use strict;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::Data::FormValidator::Multi::Nested;

# run all the test methods
Test::Data::FormValidator::Multi::Nested->runtests;
