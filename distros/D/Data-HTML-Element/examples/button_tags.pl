#!/usr/bin/env perl

use strict;
use warnings;

use Data::HTML::Element::Button;
use Tags::Output::Raw;

my $obj = Data::HTML::Element::Button->new(
        # Tags(3pm) structure.
        'data' => [
                ['b', 'span'],
                ['d', 'Button'],
                ['e', 'span'],
        ],
        'data_type' => 'tags',
);

my $tags = Tags::Output::Raw->new;

# Serialize data to output.
$tags->put(@{$obj->data});
my $data = $tags->flush(1);

# Print out.
print 'Data (serialized): '.$data."\n";
print 'Data type: '.$obj->data_type."\n";
print 'Form method: '.$obj->form_method."\n";
print 'Type: '.$obj->type."\n";

# Output:
# Data (serialized): <span>Button</span>
# Data type: tags
# Form method: get
# Type: button