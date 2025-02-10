#!/usr/bin/env perl

use strict;
use warnings;

use Data::Icon;
use Unicode::UTF8 qw(decode_utf8 encode_utf8);

my $obj = Data::Icon->new(
        'bg_color' => 'grey',
        'char' => decode_utf8('†'),
        'color' => 'red',
);

# Print out.
print "Character: ".encode_utf8($obj->char)."\n";
print "CSS color: ".$obj->color."\n";
print "CSS background color: ".$obj->bg_color."\n";

# Output:
# Character: †
# CSS color: red
# CSS background color: grey