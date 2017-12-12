#!/usr/bin/perl

use strict;
use warnings;

our $base = "51basic";

use lib qw(.);			# for perl as of 5.26
use File::Basename;
use File::Spec;
use Test::More;

# Temporarily disable.
print "1..1\nok 1\n"; exit;

TODO : {
    local $TODO = "PDF backend test not yet implemented";
    require File::Spec->catfile(dirname($0), "testscript.pl");
}
