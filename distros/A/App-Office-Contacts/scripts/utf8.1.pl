#!/usr/bin/env perl

use feature 'say';
use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.
use open      qw(:std :utf8);    # Undeclared streams in UTF-8.
use charnames qw(:full :short);  # Unneeded in v5.16.

use Text::CSV::Encoded;

# ---------------

my(@my_data) = ('Léon Brocard', 'Reichwaldstraße', 'Böhme', 'ʎ ʏ ʐ ʑ ʒ ʓ ʙ ʚ', 'Πηληϊάδεω Ἀχιλῆος', 'ΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔΔ');
my(@lc_data) = map{lc} @my_data;
my(@uc_data) = map{uc} @my_data;

open(OUT, '> :encoding(UTF-8)', 'data/utf8.1.log');
say OUT 'row, original, lc, uc';
say OUT "$_, $my_data[$_], $lc_data[$_], $uc_data[$_]" for (0 .. $#lc_data);
close OUT;

my($csv) = Text::CSV::Encoded -> new({allow_whitespace => 1, encoding_in => 'utf8'});
open my $io, '<', 'data/utf8.1.log';
$csv -> column_names($csv -> getline($io) );
my($data) = $csv -> getline_hr_all($io);
close $io;

open(OUT, '> :encoding(UTF-8)', 'data/utf8.2.log');
say OUT 'row, original, lc, uc';
say OUT "$$_{row}, $$_{original}, $$_{lc}, $$_{uc}" for @$data;
close OUT;

say 'data/utf8.1.log should be identical to data/utf8.2.log';
