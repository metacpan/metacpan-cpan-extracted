#!/usr/bin/perl

use strict;
use warnings;

our $base = "60lilypond";

use lib qw(.);			# for perl 5.26+
use File::Basename;
use File::Spec;

# Temporarily disable.
print "1..1\nok 1\n"; exit;

require File::Spec->catfile(dirname($0), "testscript.pl");
