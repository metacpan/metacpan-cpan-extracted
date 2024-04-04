#!/usr/bin/env perl

use strict;
use warnings;

use DateTime;
use DateTime::Format::PDF;

# Object.
my $obj = DateTime::Format::PDF->new;

# Example date.
my $dt = DateTime->now;

# Format.
my $pdf_date = $obj->format_datetime($dt);

# Print out.
print "PDF date: $pdf_date\n";

# Output like:
# PDF date: D:20240401084337+0000