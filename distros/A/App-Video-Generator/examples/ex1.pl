#!/usr/bin/env perl

# Pragmas.
use strict;
use warnings;

# Modules.
use App::Video::Generator;

# Run.
App::Video::Generator->new->run;

# Output like:
# Usage: /tmp/7b3GEofrss [-d duration] [-f fps] [-h]
#         [-i input_dir] [-s size] [-v] [--version] output_file
#
#         -d duration     Duration in numeric value or with ms/s/min/h suffix
#                         (default value is 10000 [=10s]).
#         -f fps          Frame rate
#         -h              Print help.
#         -i input_dir    Input directory with images (default value is nothing).
#         -s size         Size (default value is 1920x1080).
#         -v              Verbose mode.
#         --version       Print version.