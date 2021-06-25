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
# Usage: ./ex1.pl [-d stow_dir] [-h] [--version] command
#         -d stow_dir     Stow directory (default value is '/usr/local/stow').
#         -h              Help.
#         --version       Print version.
#         command         Command for which is stow dist looking.