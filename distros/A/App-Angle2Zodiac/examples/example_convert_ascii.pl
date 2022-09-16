#!/usr/bin/env perl

use strict;
use warnings;

use App::Angle2Zodiac;

# Arguments.
@ARGV = (
        '-a',
        212.5247100,
);

# Run.
exit App::Angle2Zodiac->new->run;

# Output:
# 2 sc 31′28.9560′′