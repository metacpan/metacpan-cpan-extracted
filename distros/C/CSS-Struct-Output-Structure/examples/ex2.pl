#!/usr/bin/env perl

use strict;
use warnings;

use CSS::Struct::Output::Structure;
use Data::Printer;

my $css = CSS::Struct::Output::Structure->new(
       'output_handler' => \*STDOUT,
);

# Set structure.
$css->put(['c', 'Comment']);
$css->put(['a', 'charset', 'utf-8']);
$css->put(['s', 'selector#id']);
$css->put(['s', 'div div']);
$css->put(['s', '.class']);
$css->put(['d', 'weight', '100px']);
$css->put(['d', 'font-size', '10em']);
$css->put(['e']);

# Get structure.
$css->flush;

# Output:
# ['c', 'comment']
# ['a', 'charset', 'utf-8']
# ['s', 'selector#id']
# ['s', 'div div']
# ['s', '.class']
# ['d', 'weight', '100px']
# ['d', 'font-size', '10em']
# ['e']