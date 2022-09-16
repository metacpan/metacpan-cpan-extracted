#!/usr/bin/env perl

use strict;
use warnings;

use Data::HTML::Form;

my $obj = Data::HTML::Form->new;

# Print out.
print 'Method: '.$obj->method."\n";

# Output:
# Method: get