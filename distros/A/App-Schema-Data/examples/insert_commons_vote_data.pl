#!/usr/bin/env perl

# Need to deploy sqlite.db via schema-deploy dbi:SQLite:dbname=sqlite.db Schema::Commons::Vote

use strict;
use warnings;

use App::Schema::Data;

# Arguments.
@ARGV = (
        'dbi:SQLite:dbname=sqlite.db',
        'Schema::Data::Commons::Vote',
);

# Run.
exit App::Schema::Data->new->run;

# Output like:
# Schema data from 'Schema::Data::Commons::Vote' was inserted to 'dbi:SQLite:dbname=sqlite.db'.