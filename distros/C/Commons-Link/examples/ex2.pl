#!/usr/bin/env perl

use strict;
use warnings;

use Commons::Link;

# Object.
my $obj = Commons::Link->new;

# Input name.
my $commons_file = 'File:Michal from Czechia.jpg';

# URL to file.
my $commons_url = $obj->link($commons_file);

# Print out.
print 'Input file: '.$commons_file."\n";
print 'Output link: '.$commons_url."\n";

# Output:
# Input file: File:Michal from Czechia.jpg
# Output link: http://upload.wikimedia.org/wikipedia/commons/a/a4/Michal_from_Czechia.jpg