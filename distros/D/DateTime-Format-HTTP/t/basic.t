#!/usr/bin/perl -w
use strict;
use lib 'inc';
use Test::More tests => 2;

BEGIN {
    use_ok 'DateTime::Format::HTTP';
}

pass("All done");

