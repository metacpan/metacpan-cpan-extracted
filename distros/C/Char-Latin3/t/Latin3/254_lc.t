# encoding: Latin3
# This file is encoded in Latin-3.
die "This file is not encoded in Latin-3.\n" if q{ } ne "\x82\xa0";

use strict;
use Latin3;

my $__FILE__ = __FILE__;

my %lc = ();
@lc{qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)} =
    qw(a b c d e f g h i j k l m n o p q r s t u v w x y z);
%lc = (%lc,
    "\xA1" => "\xB1", # LATIN LETTER H WITH STROKE
    "\xA6" => "\xB6", # LATIN LETTER H WITH CIRCUMFLEX
    "\xAA" => "\xBA", # LATIN LETTER S WITH CEDILLA
    "\xAB" => "\xBB", # LATIN LETTER G WITH BREVE
    "\xAC" => "\xBC", # LATIN LETTER J WITH CIRCUMFLEX
    "\xAF" => "\xBF", # LATIN LETTER Z WITH DOT ABOVE
    "\xC0" => "\xE0", # LATIN LETTER A WITH GRAVE
    "\xC1" => "\xE1", # LATIN LETTER A WITH ACUTE
    "\xC2" => "\xE2", # LATIN LETTER A WITH CIRCUMFLEX
    "\xC4" => "\xE4", # LATIN LETTER A WITH DIAERESIS
    "\xC5" => "\xE5", # LATIN LETTER C WITH DOT ABOVE
    "\xC6" => "\xE6", # LATIN LETTER C WITH CIRCUMFLEX
    "\xC7" => "\xE7", # LATIN LETTER C WITH CEDILLA
    "\xC8" => "\xE8", # LATIN LETTER E WITH GRAVE
    "\xC9" => "\xE9", # LATIN LETTER E WITH ACUTE
    "\xCA" => "\xEA", # LATIN LETTER E WITH CIRCUMFLEX
    "\xCB" => "\xEB", # LATIN LETTER E WITH DIAERESIS
    "\xCC" => "\xEC", # LATIN LETTER I WITH GRAVE
    "\xCD" => "\xED", # LATIN LETTER I WITH ACUTE
    "\xCE" => "\xEE", # LATIN LETTER I WITH CIRCUMFLEX
    "\xCF" => "\xEF", # LATIN LETTER I WITH DIAERESIS
    "\xD1" => "\xF1", # LATIN LETTER N WITH TILDE
    "\xD2" => "\xF2", # LATIN LETTER O WITH GRAVE
    "\xD3" => "\xF3", # LATIN LETTER O WITH ACUTE
    "\xD4" => "\xF4", # LATIN LETTER O WITH CIRCUMFLEX
    "\xD5" => "\xF5", # LATIN LETTER G WITH DOT ABOVE
    "\xD6" => "\xF6", # LATIN LETTER O WITH DIAERESIS
    "\xD8" => "\xF8", # LATIN LETTER G WITH CIRCUMFLEX
    "\xD9" => "\xF9", # LATIN LETTER U WITH GRAVE
    "\xDA" => "\xFA", # LATIN LETTER U WITH ACUTE
    "\xDB" => "\xFB", # LATIN LETTER U WITH CIRCUMFLEX
    "\xDC" => "\xFC", # LATIN LETTER U WITH DIAERESIS
    "\xDD" => "\xFD", # LATIN LETTER U WITH BREVE
    "\xDE" => "\xFE", # LATIN LETTER S WITH CIRCUMFLEX
);

printf("1..%d\n", scalar(keys %lc));

my $tno = 1;
for my $char (sort keys %lc){
    if (lc($char) eq $lc{$char}) {
        printf(qq{ok - $tno lc("\\x%02X") eq "\\x%02X" $^X $__FILE__\n}, ord($char), ord($lc{$char}));
    }
    else {
        printf(qq{not ok - $tno lc("\\x%02X") eq "\\x%02X" $^X $__FILE__\n}, ord($char), ord($lc{$char}));
    }
    $tno++;
}

__END__
