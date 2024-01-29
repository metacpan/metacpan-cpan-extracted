#!/usr/bin/env perl

use strict;
use warnings;

use Data::HTML::Element::Form;

my $obj = Data::HTML::Element::Form->new;

# Print out.
print 'Method: '.$obj->method."\n";

# Output:
# Method: get