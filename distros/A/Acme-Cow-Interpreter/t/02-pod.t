#!/usr/bin/perl
#
# Author:      Peter John Acklam
# Time-stamp:  2010-02-28 19:53:06 +01:00
# E-mail:      pjacklam@online.no
# URL:         http://home.online.no/~pjacklam

########################

use 5.008;              # required version of Perl
use strict;             # restrict unsafe constructs
use warnings;           # control optional warnings
use utf8;               # enable UTF-8 in source code

########################

use Test::More;

# Ensure a recent version of Test::Pod

my $tp     = 'Test::Pod';
my $min_tp = 1.22;
eval "use $tp $min_tp";
plan skip_all => "$tp $min_tp required for testing POD"
     if $@;

all_pod_files_ok();

# Emacs Local Variables:
# Emacs coding: utf-8-unix
# Emacs mode: perl
# Emacs End:
