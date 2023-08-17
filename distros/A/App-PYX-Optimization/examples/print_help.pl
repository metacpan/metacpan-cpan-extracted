#!/usr/bin/env perl

use strict;
use warnings;

use App::PYX::Optimization;

# Run.
exit App::PYX::Optimization->new->run;

# Output:
# Usage: __SCRIPT_NAME__ [-h] [--version] [filename] [-]
#         -h              Print help.
#         --version       Print version.
#         [filename]      Process on filename
#         -               Process on stdin