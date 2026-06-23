package DBIO::Shortcut::tsc;
# ABSTRACT: test fixture -- `use DBIO -tsc` shortcut stub (tier 1)

use strict;
use warnings;

sub apply { DBIO->apply_driver($_[1], 'TSC') }

1;
