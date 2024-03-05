#!/usr/bin/env perl

use strict;
use warnings;

use Data::Text::Simple;

my $obj = Data::Text::Simple->new(
        'id' => 7,
        'lang' => 'en',
        'text' => 'This is a text.',
);

# Print out.
print 'Id: '.$obj->id."\n";
print 'Language: '.$obj->lang."\n";
print 'Text: '.$obj->text."\n";

# Output:
# Id: 7
# Language: en
# Text: This is a text.