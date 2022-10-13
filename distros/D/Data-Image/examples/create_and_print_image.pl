#!/usr/bin/env perl

use strict;
use warnings;

use Data::Image;

my $obj = Data::Image->new(
        'author' => 'Zuzana Zonova',
        'comment' => 'Michal from Czechia',
        'height' => 2730,
        'size' => 1040304,
        'url' => 'https://upload.wikimedia.org/wikipedia/commons/a/a4/Michal_from_Czechia.jpg',
        'width' => 4096,
);

# Print out.
print 'Author: '.$obj->author."\n";
print 'Comment: '.$obj->comment."\n";
print 'Height: '.$obj->height."\n";
print 'Size: '.$obj->size."\n";
print 'URL: '.$obj->url."\n";
print 'Width: '.$obj->width."\n";

# Output:
# Author: Zuzana Zonova
# Comment: Michal from Czechia
# Height: 2730
# Size: 1040304
# URL: https://upload.wikimedia.org/wikipedia/commons/a/a4/Michal_from_Czechia.jpg
# Width: 4096