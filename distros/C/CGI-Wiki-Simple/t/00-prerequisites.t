#!/usr/bin/perl -w
use strict;
use diagnostics;

use Test::More tests => 1;

# First, check the prerequisites
BEGIN {
  use_ok('CGI::Wiki')
    or BAILOUT("The tests require CGI::Wiki");
};
