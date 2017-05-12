#!/usr/bin/env perl

use feature 'say';
use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.
use open      qw(:std :utf8);    # Undeclared streams in UTF-8.
use charnames qw(:full :short);  # Unneeded in v5.16.

use Encode; # For encode() and decode().

# ---------

my($correct) = 'Léon Brocard';
my($copy)    = \$correct;

say "Correct:        $correct";
say "Original:       $$copy (not overwritten the way Encode used to do)";

my($encoded)      = encode('utf-8', $correct);
my($utf8_encoded) = $correct;

utf8::encode($utf8_encoded);

say "Encoded:        $encoded";
say "utf8::encode:   $utf8_encoded";
say "Double encoded: ", encode('utf-8', $encoded);

my($decoded) = decode('utf-8', $correct);

say "Decoded: $decoded";
#say "Double decoded: ", decode('utf-8', $decoded);
say "Original:       $$copy (not overwritten the way Encode used to do)";
