#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Raw;
use CSS::Struct::Output::Indent;

if (@ARGV < 1) {
        print STDERR "Usage: $0 indent\n";
        exit 1;
}
my $indent = $ARGV[0];

my $css;
my %params = (
        'output_handler' => \*STDOUT,
);
if ($indent) {
        $css = CSS::Struct::Output::Indent->new(%params);
} else {
        $css = CSS::Struct::Output::Raw->new(%params);
}

$css->put(['c', 'comment']);
$css->put(['a', '@charset', 'utf-8']);
$css->put(['s', 'selector#id']);
$css->put(['s', 'div div']);
$css->put(['s', '.class']);
$css->put(['d', 'weight', '100px']);
$css->put(['d', 'font-size', '10em']);
$css->put(['e']);

# Flush to output.
$css->flush;
print "\n";

# Output without argument:
# Usage: __SCRIPT__ indent

# Output with argument 0:
# /*comment*/@charset "utf-8";selector#id,div div,.class{weight:100px;font-size:10em;}

# /* comment */
# Output with argument 1:
# @charset "utf-8";
# selector#id, div div, .class {
#         weight: 100px;
#         font-size: 10em;
# }