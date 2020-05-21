#!/usr/bin/env perl

use strict;
use warnings;

use CAD::AutoCAD::Detect qw(detect_dwg_file);
use File::Temp qw(tempfile);
use IO::Barf qw(barf);
use MIME::Base64;

# Data in base64.
my $data = <<'END';
QUMxMDAyAAAAAAAAAAAAAAAK
END

# Temp file.
my (undef, $temp_file) = tempfile();

# Save data to file.
barf($temp_file, decode_base64($data));

# Check file.
my $dwg_magic = detect_dwg_file($temp_file);

# Print out.
if ($dwg_magic) {
        print "File '$temp_file' is DWG file.\n";
} else {
        print "File '$temp_file' isn't DWG file.\n";
}

# Output like:
# File '%s' isn't DWG file.