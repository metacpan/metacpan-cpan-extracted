#!/usr/bin/env perl

use strict;
use warnings;

use DateTime::Format::PDF;

# Object.
my $obj = DateTime::Format::PDF->new;

# Parse date.
my $dt = $obj->parse_datetime("D:20240401084337-01'30");

# Print out.
print $dt->strftime("%a, %d %b %Y %H:%M:%S %z")."\n";

# Output like:
# Mon, 01 Apr 2024 08:43:37 -0130