#!/usr/bin/env perl

use strict;
use warnings;

use App::Translit::String;

# Run.
exit App::Translit::String->new->run;

# Print version.
sub VERSION_MESSAGE {
       print "9.99\n";
       exit 0;
}

# Output:
# Usage: /tmp/vm3pgIQWej [-h] [-r] [-t table] [--version]
#         string
# 
#         -h              Print help.
#         -r              Reverse transliteration.
#         -t table        Transliteration table (default value is 'ISO/R 9').
#         --version       Print version.