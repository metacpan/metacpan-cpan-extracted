#!/usr/bin/env perl

use strict;
use warnings;

use App::PYX2XML;

# Run.
exit App::PYX2XML->new->run;

# Output:
# Usage: ./examples/ex1.pl [-e in_enc] [-h] [-i] [-s no_simple] [--version] [filename] [-]
#         -e in_enc       Input encoding (default value is utf-8).
#         -h              Print help.
#         -i              Indent output.
#         -s no_simple    List of element, which cannot be a simple like <element/>. Separator is comma.
#         --version       Print version.
#         [filename]      Process on filename
#         [-]             Process on stdin