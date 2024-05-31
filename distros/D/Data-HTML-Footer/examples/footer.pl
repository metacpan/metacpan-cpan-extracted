#!/usr/bin/env perl

use strict;
use warnings;

use Data::HTML::Footer;

my $obj = Data::HTML::Footer->new(
        'author' => 'John',
        'author_url' => 'https://example.com',
        'copyright_years' => '2023-2024',
        'height' => '40px',
        'version' => 0.07,
        'version_url' => '/changes',
);

# Print out.
print 'Author: '.$obj->author."\n";
print 'Author URL: '.$obj->author_url."\n";
print 'Copyright years: '.$obj->copyright_years."\n";
print 'Footer height: '.$obj->height."\n";
print 'Version: '.$obj->version."\n";
print 'Version URL: '.$obj->version_url."\n";

# Output:
# Author: John
# Author URL: https://example.com
# Copyright years: 2023-2024
# Footer height: 40px
# Version: 0.07
# Version URL: /changes