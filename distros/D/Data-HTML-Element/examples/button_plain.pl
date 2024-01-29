#!/usr/bin/env perl

use strict;
use warnings;

use Data::HTML::Element::Button;

my $obj = Data::HTML::Element::Button->new(
        # Plain content.
        'data' => [
                'Button',
        ],
        'data_type' => 'plain',
);

# Serialize data to output.
my $data = join ' ', @{$obj->data};

# Print out.
print 'Data: '.$data."\n";
print 'Data type: '.$obj->data_type."\n";
print 'Form method: '.$obj->form_method."\n";
print 'Type: '.$obj->type."\n";

# Output:
# Data: Button
# Data type: plain
# Form method: get
# Type: button