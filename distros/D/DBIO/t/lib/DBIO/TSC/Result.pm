package DBIO::TSC::Result;
# ABSTRACT: test fixture -- Result component loaded by the -tsc shortcut

use strict;
use warnings;

use base 'DBIO::Base';

sub tsc_marker { 42 }

1;
