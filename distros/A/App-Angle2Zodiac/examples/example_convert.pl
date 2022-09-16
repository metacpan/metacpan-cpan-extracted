#!/usr/bin/env perl

use strict;
use warnings;

use App::Angle2Zodiac;

# Arguments.
@ARGV = (
        212.5247100,
);

# Run.
exit App::Angle2Zodiac->new->run;

# Output:
# 2°♏31′28.9560′′