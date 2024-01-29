#!/usr/bin/env perl

use strict;
use warnings;

use Data::HTML::Element::Textarea;

my $obj = Data::HTML::Element::Textarea->new(
       'autofocus' => 1,
       'css_class' => 'textarea',
       'id' => 'textarea-id',
       'label' => 'Textarea label',
       'value' => 'Textarea value',
);

# Print out.
print 'Autofocus: '.$obj->autofocus."\n";
print 'CSS class: '.$obj->css_class."\n";
print 'Disabled: '.$obj->disabled."\n";
print 'Id: '.$obj->id."\n";
print 'Label: '.$obj->label."\n";
print 'Readonly: '.$obj->readonly."\n";
print 'Required: '.$obj->required."\n";
print 'Value: '.$obj->value."\n";

# Output:
# Autofocus: 1
# CSS class: textarea
# Disabled: 0
# Id: textarea-id
# Label: Textarea label
# Readonly: 0
# Required: 0
# Value: Textarea value