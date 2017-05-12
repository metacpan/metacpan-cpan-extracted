#!/usr/bin/env perl
use strict;
use warnings;

BEGIN {
  if ($^O ne 'MSWin32') {
    print "1..0 # Skip This testing is for Win32\n";
    exit(0);
  }
}

use Test::More  tests => 3;

require_ok("Win32");
require_ok("Win32::API");
require_ok("Win32::API::Type");

# Spit out a big diagnostic if we failed.
eval { require Win32; require Win32::API; require Win32::API::Type; 1; }
  or diag "\n\n\nYou need to install the Win32 and Win32::API modules.\n\nThese should be included by default in most modern Win32 Perl distributions.\n\n\n";
