#!/usr/bin/env perl

use strict;
use warnings;

use Data::Image;
use DateTime;

my $obj = Data::Image->new(
        'author' => 'Zuzana Zonova',
        'comment' => 'Michal from Czechia',
        'dt_created' => DateTime->new(
                'day' => 1,
                'month' => 1,
                'year' => 2022,
        ),
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
print 'Date and time the image was created: '.$obj->dt_created."\n";

# Output:
# Author: Zuzana Zonova
# Comment: Michal from Czechia
# Height: 2730
# Size: 1040304
# URL: https://upload.wikimedia.org/wikipedia/commons/a/a4/Michal_from_Czechia.jpg
# Width: 4096
# Date and time the photo was created: 2022-01-01T00:00:00