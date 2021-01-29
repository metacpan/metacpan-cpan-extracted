#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent::ANSIColor;

my $css = CSS::Struct::Output::Indent::ANSIColor->new(
        'output_handler' => \*STDOUT,
);

$css->put(['c', 'Nice selector.']);
$css->put(['a', '@import', 'file.css']);
$css->put(['s', 'selector#id']);
$css->put(['s', 'div div']);
$css->put(['s', '.class']);
$css->put(['s', 'p.class']);
$css->put(['d', 'weight', '100px']);
$css->put(['d', 'font-size', '10em']);
$css->put(['d', '--border-color', 'hsl(0, 0%, 83%)']);
$css->put(['e']);
$css->flush;
print "\n";

# Output (in colors):
# /* Nice selector. */
# @import "file.css";
# selector#id, div div, .class, p.class {
#         weight: 100px;
#         font-size: 10em;
#         --border-color: hsl(0, 0%, 83%);
# }