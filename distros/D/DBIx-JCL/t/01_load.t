#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 2;

BEGIN {
    chdir 't' if -d 't';
}
use lib '../lib';

use_ok( 'DBIx::JCL' );
require_ok( 'DBIx::JCL' );

exit 0;
