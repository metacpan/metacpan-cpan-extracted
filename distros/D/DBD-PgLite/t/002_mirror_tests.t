#!/usr/bin/perl -w

use strict;
use Test::More tests => 1;

use DBD::PgLite::MirrorPgToSQLite;

# Hard to design automatic tests for this since environments vary so much.
# Might later do some tests given suitable environment variables.
# This is just a placeholder

is ( 1, 1, 'no-op');
