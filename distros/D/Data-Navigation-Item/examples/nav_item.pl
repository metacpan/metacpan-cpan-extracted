#!/usr/bin/env perl

use strict;
use warnings;

use Data::Navigation::Item;

my $obj = Data::Navigation::Item->new(
        'class' => 'nav-item',
        'desc' => 'This is description',
        'id' => 1,
        'image' => '/img/foo.png',
        'location' => '/title',
        'title' => 'Title',
);

# Print out.
print 'Class: '.$obj->class."\n";
print 'Description: '.$obj->desc."\n";
print 'Id: '.$obj->id."\n";
print 'Image: '.$obj->image."\n";
print 'Location: '.$obj->location."\n";
print 'Title: '.$obj->title."\n";

# Output:
# Class: nav-item
# Description: This is description
# Id: 1
# Image: /img/foo.png
# Location: /title
# Title: Title