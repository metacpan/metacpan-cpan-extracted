#!/usr/bin/env perl

use strict;
use warnings;

use IO::Barf qw(barf);
use File::Temp;
use CPAN::Changes;
use CPAN::Changes::Utils qw(construct_copyright_years);

# Content.
my $content = <<'END';
0.02 2019-07-13
 - item #2
 - item #3

0.01 2009-07-06
 - item #1
END

# Temporary file.
my $temp_file = File::Temp->new->filename;

# Barf out.
barf($temp_file, $content);

# Create CPAN::Changes instance.
my $changes = CPAN::Changes->load($temp_file);

# Construct copyright years.
my $copyright_years = construct_copyright_years($changes);

# Print copyright years to stdout.
print "Copyright years: $copyright_years\n";

# Unlink temporary file.
unlink $temp_file;

# Output:
# Copyright years: 2009-2019