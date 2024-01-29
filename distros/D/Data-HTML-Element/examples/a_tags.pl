#!/usr/bin/env perl

use strict;
use warnings;

use Data::HTML::Element::A;
use Tags::Output::Raw;

my $obj = Data::HTML::Element::A->new(
        'css_class' => 'link',
        # Tags(3pm) structure.
        'data' => [
                ['b', 'span'],
                ['a', 'class', 'span-link'],
                ['d', 'Link'],
                ['e', 'span'],
        ],
        'data_type' => 'tags',
        'url' => 'https://skim.cz',
);

my $tags = Tags::Output::Raw->new;

# Serialize data to output.
$tags->put(@{$obj->data});
my $data = $tags->flush(1);

# Print out.
print 'CSS class: '.$obj->css_class."\n";
print 'Data (serialized): '.$data."\n";
print 'Data type: '.$obj->data_type."\n";
print 'URL: '.$obj->url."\n";

# Output:
# CSS class: link
# Data (serialized): <span class="span-link">Link</span>
# Data type: tags
# URL: https://skim.cz