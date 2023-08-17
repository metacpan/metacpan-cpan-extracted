#!/usr/bin/env perl

use strict;
use warnings;

use Data::Message::Simple;

my $obj = Data::Message::Simple->new(
        'lang' => 'en',
        'text' => 'This is text message.',
);

# Print out.
print 'Message type: '.$obj->type."\n";
print 'ISO 639-1 language code: '.$obj->lang."\n";
print 'Text: '.$obj->text."\n";

# Output:
# Message type: info
# ISO 639-1 language code: en
# Text: This is text message.