#!/usr/bin/env perl

use strict;
use warnings;

use App::Schema::Deploy;

# Arguments.
@ARGV = (
        'dbi:SQLite:dbname=sqlite.db',
        'Schema::Commons::Vote',
);

# Run.
exit App::Schema::Deploy->new->run;

# Output like:
# Schema (v0.1.0) from 'Schema::Commons::Vote' was deployed to 'dbi:SQLite:dbname=ex2.db'.