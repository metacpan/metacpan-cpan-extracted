#!/usr/bin/env perl

use strict;
use warnings;

use App::Pod::Example;

# Arguments.
@ARGV = (
        '-e',
        '-p',
        'App::Pod::Example',
);

# Run.
App::Pod::Example->new->run;

# Output:
# -- this code with enumerated lines --