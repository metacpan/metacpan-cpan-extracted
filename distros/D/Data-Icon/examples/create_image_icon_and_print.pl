#!/usr/bin/env perl

use strict;
use warnings;

use Data::Icon;

my $obj = Data::Icon->new(
        'alt' => 'Foo icon',
        'url' => 'https://example.com/foo.png',
);

# Print out.
print "Alternate text: ".$obj->alt."\n";
print "Icon URL: ".$obj->url."\n";

# Output:
# Alternate text: Foo icon
# Icon URL: https://example.com/foo.png