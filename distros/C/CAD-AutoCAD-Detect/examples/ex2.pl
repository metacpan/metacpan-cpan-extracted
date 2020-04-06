#!/usr/bin/env perl

use strict;
use warnings;

use CAD::AutoCAD::Detect qw(detect_dwg_file);

# Arguments.
if (@ARGV < 1) {
        print STDERR "Usage: $0 file\n";
        exit 1;
}
my $file = $ARGV[0];

# Check DWG file.
my $dwg_flag = detect_dwg_file($file);

# Print out.
if ($dwg_flag) {
        print "File '$file' is DWG file.\n";
} else {
        print "File '$file' isn't DWG file.\n";
}

# Output:
# Usage: detect-dwg-file file