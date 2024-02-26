#!/usr/bin/env perl

use strict;
use warnings;

use App::ISBN::Check;

# Arguments.
@ARGV = (
        -h,
);

# Run.
exit App::ISBN::Check->new->run;

# Output:
# Usage: ./print_help.pl [-h] [--version] file_with_isbns
#         -h              Print help.
#         --version       Print version.
#         file_with_isbns File with ISBN strings, one per line.