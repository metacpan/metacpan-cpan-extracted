#!/usr/bin/env perl

use strict;
use warnings;

use Data::HTML::Element::Button;

my $obj = Data::HTML::Element::Button->new;

# Print out.
print 'Data type: '.$obj->data_type."\n";
print 'Form method: '.$obj->form_method."\n";
print 'Type: '.$obj->type."\n";

# Output:
# Data type: plain
# Form method: get
# Type: button