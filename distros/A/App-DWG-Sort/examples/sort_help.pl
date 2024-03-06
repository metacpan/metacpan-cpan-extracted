#!/usr/bin/env perl

use strict;
use warnings;

use App::DWG::Sort;

# Arguments.
@ARGV = (
        '-h',
);

# Run.
exit App::DWG::Sort->new->run;

# Output like:
# Usage: ./sort_help.pl [-h] [--version] directory
#         -h              Print help.
#         --version       Print version.
#         directory       Directory with DWG files.