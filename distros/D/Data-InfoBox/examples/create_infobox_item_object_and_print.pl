#!/usr/bin/env perl

use strict;
use warnings;

use Data::InfoBox::Item;
use Data::Text::Simple;

my $obj = Data::InfoBox::Item->new(
        'icon_url' => 'https://example.com/foo.png',
        'text' => Data::Text::Simple->new(
                'text' => 'Funny item'
        ),
        'url' => 'https://skim.cz',
);

# Print out.
print "Icon URL: ".$obj->icon_url."\n";
print "Text: ".$obj->text->text."\n";
print "URL: ".$obj->url."\n";

# Output:
# Icon URL: https://example.com/foo.png
# Text: Funny item
# URL: https://skim.cz