#!/usr/bin/env perl

use strict;
use warnings;

use Commons::Link;

# Object.
my $obj = Commons::Link->new;

# Input name.
my $commons_file = 'File:Michal from Czechia.jpg';

# URL to thumbnail file.
my $commons_url = $obj->thumb_link($commons_file, 200);

# Print out.
print 'Input file: '.$commons_file."\n";
print 'Output thumbnail link: '.$commons_url."\n";

# Output:
# Input file: File:Michal from Czechia.jpg
# Output thumbnail link: http://upload.wikimedia.org/wikipedia/commons/thumb/a/a4/Michal_from_Czechia.jpg/200px-Michal_from_Czechia.jpg