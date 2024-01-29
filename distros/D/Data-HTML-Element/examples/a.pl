#!/usr/bin/env perl

use strict;
use warnings;

use Data::HTML::Element::A;

my $obj = Data::HTML::Element::A->new(
        'css_class' => 'link',
        'data' => ['Michal Josef Spacek homepage'],
        'url' => 'https://skim.cz',
);

# Print out.
print 'CSS class: '.$obj->css_class."\n";
print 'Data: '.(join '', @{$obj->data})."\n";
print 'Data type: '.$obj->data_type."\n";
print 'URL: '.$obj->url."\n";

# Output:
# CSS class: link
# Data: Michal Josef Spacek homepage
# Data type: plain
# URL: https://skim.cz