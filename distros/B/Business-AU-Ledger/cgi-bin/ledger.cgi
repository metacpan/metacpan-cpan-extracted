#!/usr/bin/perl
#
# Name:
# ledger.cgi.

use strict;
use warnings;

use Business::AU::Ledger;

# ----------------

Business::AU::Ledger -> new -> run;
