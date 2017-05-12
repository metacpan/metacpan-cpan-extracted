#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use App::Image::Generator;

# Run.
App::Image::Generator->new->run;

# Output like:
# Usage: __SCRIPT__ [-h] [-i input_dir] [-s size] [-v]
#         [--version] output_file
# 
#         -h              Print help.
#         -i input_dir    Input directory with images (default value is nothing).
#         -s size         Size (default value is 1920x1080).
#         -v              Verbose mode.
#         --version       Print version.