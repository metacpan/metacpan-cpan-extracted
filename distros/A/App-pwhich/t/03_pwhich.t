use strict;
use warnings;
use Test::More tests => 1;
use Test::Script;
use File::Which;

# Can we find the tool with the command line version?
script_runs(
  [ 'bin/pwhich', 'perl' ],
  'Found perl with pwhich',
);
