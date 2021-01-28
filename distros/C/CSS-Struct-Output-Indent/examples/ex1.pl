#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Indent;

my $css = CSS::Struct::Output::Indent->new(
        'output_handler' => \*STDOUT,
);

$css->put(['s', 'selector#id']);
$css->put(['s', 'div div']);
$css->put(['s', '.class']);
$css->put(['d', 'weight', '100px']);
$css->put(['d', 'font-size', '10em']);
$css->put(['e']);
$css->flush;
print "\n";

# Output:
# selector#id, div div, .class {
#         weight: 100px;
#         font-size: 10em;
# }