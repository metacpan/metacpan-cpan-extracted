# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

use Test::More qw(no_plan);
use strict;
use utf8;

use Convert::CEGH::Transliterate 'transliterate';

is ( 1, 1, "loaded." );


my $word = "አዳም";

my $coptic = transliterate ( "cop", $word );
my $ethio  = transliterate ( "eth", $word );
my $greek  = transliterate ( "ell", $word );
my $hebrew = transliterate ( "heb", $word );


is ( $coptic, "ΑΔΜ", "Coptic Transliteration" );
is ( $ethio,  "አደመ", "Ge'ez  Transliteration"  );
is ( $greek,  "ΑΔΜ", "Greek  Transliteration" );
is ( $hebrew, "מדא", "Hebrew Transliteration"  );
