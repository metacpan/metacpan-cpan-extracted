# DO NOT EDIT! This file is written by perl_setup_dist.
# If needed, you can add content at the end of the file.

#!/usr/bin/perl

use strict;
use warnings;
use Test2::V0;

our $VERSION = 0.01;

BEGIN {
  ok(eval 'use App::UpdateConfig; 1', 'use App::UpdateConfig');  ## no critic (ProhibitStringyEval, RequireCheckingReturnValueOfEval)
}
{
  no warnings 'once';  ## no critic (ProhibitNoWarnings)
  note("Testing App::UpdateConfig $App::UpdateConfig::VERSION, Perl $], $^X");
}

done_testing;

# End of the template. You can add custom content below this line.
