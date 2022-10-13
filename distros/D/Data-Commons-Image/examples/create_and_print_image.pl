#!/usr/bin/env perl

use strict;
use warnings;

use Data::Commons::Image;
use DateTime;

my $obj = Data::Commons::Image->new(
        'author' => 'Zuzana Zonova',
        'comment' => 'Michal from Czechia',
        'commons_name' => 'Michal_from_Czechia.jpg',
        'dt_created' => DateTime->new(
                'day' => 1,
                'month' => 1,
                'year' => 2022,
        ),
        'dt_uploaded' => DateTime->new(
                'day' => 14,
                'month' => 7,
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
print 'Wikimedia Commons name: '.$obj->commons_name."\n";
print 'Height: '.$obj->height."\n";
print 'Size: '.$obj->size."\n";
print 'URL: '.$obj->url."\n";
print 'Width: '.$obj->width."\n";
print 'Date and time the photo was created: '.$obj->dt_created."\n";
print 'Date and time the photo was uploaded: '.$obj->dt_uploaded."\n";

# Output:
# Author: Zuzana Zonova
# Comment: Michal from Czechia
# Wikimedia Commons name: Michal_from_Czechia.jpg
# Height: 2730
# Size: 1040304
# URL: https://upload.wikimedia.org/wikipedia/commons/a/a4/Michal_from_Czechia.jpg
# Width: 4096
# Date and time the photo was created: 2022-01-01T00:00:00
# Date and time the photo was uploaded: 2022-07-14T00:00:00