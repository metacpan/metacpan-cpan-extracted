#!/usr/bin/env perl

use strict;
use warnings;

use Data::HTML::Element::Option;

my $obj = Data::HTML::Element::Option->new(
       'css_class' => 'opt',
       'id' => 7,
       'label' => 'Audi',
       'selected' => 1,
       'value' => 'audi',
);

# Print out.
print 'Id: '.$obj->id."\n";
print 'CSS class: '.$obj->css_class."\n";
print 'Label: '.$obj->label."\n";
print 'Value: '.$obj->value."\n";
print 'Selected: '.$obj->selected."\n";

# Output:
# Id: 7
# CSS class: opt
# Label: Audi
# Value: audi
# Selected: 1