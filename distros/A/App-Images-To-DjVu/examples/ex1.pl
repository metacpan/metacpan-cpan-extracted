#!/usr/bin/env perl

use strict;
use warnings;

use App::Images::To::DjVu;

# Arguments.
@ARGV = (
        '-h',
);

# Run.
exit App::Images::To::DjVu->new->run;

# Output like:
# Usage: ./ex1.pl [-e encoder] [-h] [-o out_file] [-q] [--version] images_list_file
#         -e encoder              Encoder (default value is 'c44').
#         -h                      Print help.
#         -o out_file             Output file (default value is 'output.djvu').
#         -q                      Quiet mode.
#         --version               Print version.
#         images_list_file        Text file with images list.