#!/usr/bin/perl 

use Test::More tests=>5;

use strict;
use IO::File;
use BibTeX::Parser;
my $fh = new IO::File "t/bibs/english.bib", "r" ;

my $parser = new BibTeX::Parser($fh);
$parser->read();
is($parser->n(), 8, "Number of cached entries is correct");
is(join(", ", sort @{$parser->entrykeys()}),
   "Carey, Cooper, Fowler-KingsEnglish, Fowler-ModernEnglish, Gowers, Hart, Partridge, Quirk-CompGram", "Keys are correct");
is($parser->has('Quirk-CompGram'), 1, "Entry presence check is correc");
is($parser->has('QuirkCompGram'), "", "Entry absence check is correc");
is($parser->entry('Quirk-CompGram')->to_string(), "\@BOOK{Quirk-CompGram,
    author = {Quirk, Randolph and Greenbaum, Sydney and Leach, Geoffrey and Svartnik, Jan},
    title = {A Comprehensive Grammar of the {E}nglish Language},
    publisher = {Longman},
    year = {1985},
}", "Entry check is correct");

