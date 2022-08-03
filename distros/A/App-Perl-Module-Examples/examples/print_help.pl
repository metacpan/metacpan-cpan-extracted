#!/usr/bin/env perl

use strict;
use warnings;

use App::Perl::Module::Examples;

# Arguments.
@ARGV = (
        '-h',
);

# Run.
exit App::Perl::Module::Examples->new->run;

# Output like:
# Usage: ./print_help.pl [-d] [-h] [--version]
#         -d              Debug mode.
#         -h              Print help.
#         --version       Print version.