#!/usr/bin/env perl

use strict;
use warnings;

use App::Kramerius::To::Images;

# Arguments.
@ARGV = (
        '-h',
);

# Run.
exit App::Kramerius::To::Images->new->run;

# Output like:
# Usage: ./ex1.pl [-h] [-q] [-v] [--version] [kramerius_id object_id]
#         -h              Help.
#         -q              Quiet mode.
#         -v              Verbose mode.
#         --version       Print version.
#         kramerius_id    Kramerius system id. e.g. mzk
#         object_id       Kramerius object id (could be page, series or book edition).