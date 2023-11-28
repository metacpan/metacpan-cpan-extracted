#!/usr/bin/env perl

use strict;
use warnings;

use App::Bin::Search;

# Arguments.
@ARGV = (
        '-v',
        'FFABCD',
        'D5',
);

# Run.
exit App::Bin::Search->new->run;

# Output like:
# Hexadecimal stream: FFABCD
# Size of hexadecimal stream: 24
# Looking for: D5
# FFABCD at 1bit 
# FF579A at 2bit 
# FEAF34 at 3bit 
# FD5E68 at 4bit 
# FABCD at 5bit 
# F579A at 6bit 
# EAF34 at 7bit 
# D5E68 at 8bit 
# Found D5E68 at 8 bit
# ABCD at 9bit 
# 579A at 10bit 
# AF34 at 11bit 
# 5E68 at 12bit 
# BCD at 13bit 
# 79A at 14bit 
# F34 at 15bit 
# E68 at 16bit 
# CD at 17bit 
# 9A at 18bit 
# 34 at 19bit 
# 68 at 20bit 
# D at 21bit 
# A at 22bit 
# 4 at 23bit 
# 8 at 24bit