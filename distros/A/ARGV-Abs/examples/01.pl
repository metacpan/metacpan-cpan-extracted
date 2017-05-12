#!/usr/bin/perl

use strict;
use warnings;

use ARGV::Abs ();

unless (@ARGV) {
    require File::Glob;
    @ARGV = File::Glob::bsd_glob('*');
}

ARGV::Abs->import;

print "$_\n" for @ARGV;
