#!/usr/bin/env perl

use strict;
use warnings;

use App::Perl::Module::CopyrightYears;

# Arguments.
@ARGV = (
        '-h',
);

# Run.
exit App::Perl::Module::CopyrightYears->new->run;

# Output like:
# Usage: ./print_help.pl [-d] [-h] [-s section(s)] [-y last_year] [--version]
#         -d              Debug mode.
#         -h              Print help.
#         -s section(s)   Section(s) to look (default is LICENSE AND COPYRIGHT)
#         -y last_year    Last year (default value is actual year)
#         --version       Print version.