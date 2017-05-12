# encoding: Latin4
# This file is encoded in Latin-4.
die "This file is not encoded in Latin-4.\n" if q{‚ } ne "\x82\xa0";

use strict;
use Latin4;

my $__FILE__ = __FILE__;

my %lc = ();
@lc{qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)} =
    qw(a b c d e f g h i j k l m n o p q r s t u v w x y z);
%lc = (%lc,
    "\xA1" => "\xB1", # LATIN LETTER A WITH OGONEK
    "\xA3" => "\xB3", # LATIN LETTER R WITH CEDILLA
    "\xA5" => "\xB5", # LATIN LETTER I WITH TILDE
    "\xA6" => "\xB6", # LATIN LETTER L WITH CEDILLA
    "\xA9" => "\xB9", # LATIN LETTER S WITH CARON
    "\xAA" => "\xBA", # LATIN LETTER E WITH MACRON
    "\xAB" => "\xBB", # LATIN LETTER G WITH CEDILLA
    "\xAC" => "\xBC", # LATIN LETTER T WITH STROKE
    "\xAE" => "\xBE", # LATIN LETTER Z WITH CARON
    "\xBD" => "\xBF", # LATIN LETTER ENG
    "\xC0" => "\xE0", # LATIN LETTER A WITH MACRON
    "\xC1" => "\xE1", # LATIN LETTER A WITH ACUTE
    "\xC2" => "\xE2", # LATIN LETTER A WITH CIRCUMFLEX
    "\xC3" => "\xE3", # LATIN LETTER A WITH TILDE
    "\xC4" => "\xE4", # LATIN LETTER A WITH DIAERESIS
    "\xC5" => "\xE5", # LATIN LETTER A WITH RING ABOVE
    "\xC6" => "\xE6", # LATIN LETTER AE
    "\xC7" => "\xE7", # LATIN LETTER I WITH OGONEK
    "\xC8" => "\xE8", # LATIN LETTER C WITH CARON
    "\xC9" => "\xE9", # LATIN LETTER E WITH ACUTE
    "\xCA" => "\xEA", # LATIN LETTER E WITH OGONEK
    "\xCB" => "\xEB", # LATIN LETTER E WITH DIAERESIS
    "\xCC" => "\xEC", # LATIN LETTER E WITH DOT ABOVE
    "\xCD" => "\xED", # LATIN LETTER I WITH ACUTE
    "\xCE" => "\xEE", # LATIN LETTER I WITH CIRCUMFLEX
    "\xCF" => "\xEF", # LATIN LETTER I WITH MACRON
    "\xD0" => "\xF0", # LATIN LETTER D WITH STROKE
    "\xD1" => "\xF1", # LATIN LETTER N WITH CEDILLA
    "\xD2" => "\xF2", # LATIN LETTER O WITH MACRON
    "\xD3" => "\xF3", # LATIN LETTER K WITH CEDILLA
    "\xD4" => "\xF4", # LATIN LETTER O WITH CIRCUMFLEX
    "\xD5" => "\xF5", # LATIN LETTER O WITH TILDE
    "\xD6" => "\xF6", # LATIN LETTER O WITH DIAERESIS
    "\xD8" => "\xF8", # LATIN LETTER O WITH STROKE
    "\xD9" => "\xF9", # LATIN LETTER U WITH OGONEK
    "\xDA" => "\xFA", # LATIN LETTER U WITH ACUTE
    "\xDB" => "\xFB", # LATIN LETTER U WITH CIRCUMFLEX
    "\xDC" => "\xFC", # LATIN LETTER U WITH DIAERESIS
    "\xDD" => "\xFD", # LATIN LETTER U WITH TILDE
    "\xDE" => "\xFE", # LATIN LETTER U WITH MACRON
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
