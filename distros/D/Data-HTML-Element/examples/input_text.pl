#!/usr/bin/env perl

use strict;
use warnings;

use Data::HTML::Element::Input;

my $obj = Data::HTML::Element::Input->new(
       'autofocus' => 1,
       'css_class' => 'input',
       'id' => 'address',
       'label' => 'Customer address',
       'placeholder' => 'Place address',
       'type' => 'text',
);

# Print out.
print 'Id: '.$obj->id."\n";
print 'Type: '.$obj->type."\n";
print 'CSS class: '.$obj->css_class."\n";
print 'Label: '.$obj->label."\n";
print 'Autofocus: '.$obj->autofocus."\n";
print 'Placeholder: '.$obj->placeholder."\n";

# Output:
# Id: address
# Type: text
# CSS class: input
# Label: Customer address
# Autofocus: 1
# Placeholder: Place address