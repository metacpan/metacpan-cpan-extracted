#!/usr/bin/env perl

use strict;
use warnings;

use App::Bin::Search;

# Arguments.
@ARGV = (
        '-b',
        'FFABCD',
        'D5',
);

# Run.
exit App::Bin::Search->new->run;

# Output like:
# Found 11010101111001101 at 8 bit