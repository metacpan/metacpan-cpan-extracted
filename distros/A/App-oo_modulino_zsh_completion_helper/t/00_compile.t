#!/usr/bin/env perl
use strict;
use Test::More 0.98;

use FindBin;
use lib "$FindBin::Bin/../lib";

use_ok $_ for qw(
    App::oo_modulino_zsh_completion_helper
);

done_testing;

