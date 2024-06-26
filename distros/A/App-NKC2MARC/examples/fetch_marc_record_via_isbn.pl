#!/usr/bin/env perl

use strict;
use warnings;

use App::NKC2MARC;

# Arguments.
@ARGV = (
        '978-80-7370-353-0',
);

# Run.
exit App::NKC2MARC->new->run;

# Output:
# MARC record for '978-80-7370-353-0' was saved to cnb002751696.mrc.