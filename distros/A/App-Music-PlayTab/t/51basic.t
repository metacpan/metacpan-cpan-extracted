#!/usr/bin/perl

use strict;
use warnings;

our $base = "50basic";

use lib qw(.);			# for perl as of 5.26
use File::Basename;
use File::Spec;

require File::Spec->catfile(dirname($0), "testscript.pl");
