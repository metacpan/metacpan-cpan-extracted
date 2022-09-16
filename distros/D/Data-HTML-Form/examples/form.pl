#!/usr/bin/env perl

use strict;
use warnings;

use Data::HTML::Form;

my $obj = Data::HTML::Form->new(
       'action' => '/action.pl',
       'css_class' => 'form',
       'enctype' => 'multipart/form-data',
       'id' => 'form-id',
       'label' => 'Form label',
       'method' => 'post',
);

# Print out.
print 'Action: '.$obj->action."\n";
print 'CSS class: '.$obj->css_class."\n";
print 'Enctype: '.$obj->enctype."\n";
print 'Id: '.$obj->id."\n";
print 'Label: '.$obj->label."\n";
print 'Method: '.$obj->method."\n";

# Output:
# Action: /action.pl
# CSS class: form
# Enctype: multipart/form-data
# Id: form-id
# Label: Form label
# Method: post