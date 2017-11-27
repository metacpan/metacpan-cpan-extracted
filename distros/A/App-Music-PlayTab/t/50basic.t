#!/usr/bin/perl

use strict;
use warnings;

our $base = "50basic";

use File::Basename;
use File::Spec;

$ENV{PLAYTABTEST_EXT} = "dmp";

require File::Spec->catfile(dirname($0), "testscript.pl");
