#!/usr/bin/perl -w

# Simply test that we can load the DBI and DBD::PgPP modules;
# check that we have a valid version returned from the latter

use Test::More tests => 3;
use strict;

BEGIN {
    use_ok('DBI');
    use_ok('DBD::PgPP');
};

like($DBD::PgPP::VERSION, qr/^[\d\._]+$/,
     qq{Found DBD::PgPP::VERSION as "$DBD::PgPP::VERSION"});

