#!/usr/bin/env perl

use strict;
use warnings;

use App::Stow::Check;

# Arguments.
@ARGV = (
        '-h',
);

# Run.
exit App::Stow::Check->new->run;

# Output:
# TODO