#!/usr/bin/env perl

use strict;
use warnings;

use App::Toolforge::MixNMatch;

# Run.
exit App::Toolforge::MixNMatch->new->run;

# Output:
# Usage: ./examples/ex1.pl [-h] [--version] [command] [command_args ..]
#         -h              Print help.
#         --version       Print version.
#         command         Command (diff, download, print).
#
#         command 'diff' arguments:
#                 json_file1 - JSON file #1
#                 json_file2 - JSON file #2
#                 [print_options] - Print options (type, count, year_months, users)
#         command 'download' arguments:
#                 catalog_id - Catalog ID
#                 [output_file] - Output file (default is catalog_id.json)
#         command 'print' arguments:
#                 json_file or catalog_id - Catalog ID or JSON file
#                 [print_options] - Print options (type, count, year_months, users)