#!/usr/bin/env perl

use strict;
use warnings;

use App::Image::Generator;

# Run.
App::Image::Generator->new->run;

# Output like:
# Usage: __SCRIPT__ [-h] [-i input_dir] [-p pattern] [-s size] [-v]
#         [--version] output_file
# 
#         -h              Print help.
#         -i input_dir    Input directory with images (default value is nothing).
#         -p pattern      Pattern (checkerboard).
#         -s size         Size (default value is 1920x1080).
#         -v              Verbose mode.
#         --version       Print version.