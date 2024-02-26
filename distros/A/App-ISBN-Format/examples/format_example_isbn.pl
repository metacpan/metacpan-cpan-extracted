#!/usr/bin/env perl

use strict;
use warnings;

use App::ISBN::Format;

# Arguments.
@ARGV = (
        '9788025343364',
);

# Run.
exit App::ISBN::Format->new->run;

# Output:
# 9788025343364 -> 978-80-253-4336-4