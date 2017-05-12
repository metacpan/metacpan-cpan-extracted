#!/usr/bin/perl
# Test to see if the module loads correctly.
use warnings;
use strict;
use Test::More tests => 1;

BEGIN { use_ok('DateTime::Calendar::Discordian') };

diag(
    "Testing DateTime::Calendar::Discordian $DateTime::Calendar::Discordian::VERSION, Perl $], $^X\n",
);
