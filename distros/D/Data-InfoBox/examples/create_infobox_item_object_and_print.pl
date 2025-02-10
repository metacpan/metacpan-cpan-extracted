#!/usr/bin/env perl

use strict;
use warnings;

use Data::Icon;
use Data::InfoBox::Item;
use Data::Text::Simple;

my $obj = Data::InfoBox::Item->new(
        'icon' => Data::Icon->new(
                'url' => 'https://example.com/foo.png',
        ),
        'text' => Data::Text::Simple->new(
                'text' => 'Funny item'
        ),
        'uri' => 'https://skim.cz',
);

# Print out.
print "Icon URL: ".$obj->icon->url."\n";
print "Text: ".$obj->text->text."\n";
print "URI: ".$obj->uri."\n";

# Output:
# Icon URL: https://example.com/foo.png
# Text: Funny item
# URI: https://skim.cz