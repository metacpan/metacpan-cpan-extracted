# encoding: Latin7
# This file is encoded in Latin-7.
die "This file is not encoded in Latin-7.\n" if q{ } ne "\x82\xa0";

use strict;
use Latin7;

my $__FILE__ = __FILE__;

my %lc = ();
@lc{qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)} =
    qw(a b c d e f g h i j k l m n o p q r s t u v w x y z);
%lc = (%lc,
    "\xA8" => "\xB8", # LATIN LETTER O WITH STROKE
    "\xAA" => "\xBA", # LATIN LETTER R WITH CEDILLA
    "\xAF" => "\xBF", # LATIN LETTER AE
    "\xC0" => "\xE0", # LATIN LETTER A WITH OGONEK
    "\xC1" => "\xE1", # LATIN LETTER I WITH OGONEK
    "\xC2" => "\xE2", # LATIN LETTER A WITH MACRON
    "\xC3" => "\xE3", # LATIN LETTER C WITH ACUTE
    "\xC4" => "\xE4", # LATIN LETTER A WITH DIAERESIS
    "\xC5" => "\xE5", # LATIN LETTER A WITH RING ABOVE
    "\xC6" => "\xE6", # LATIN LETTER E WITH OGONEK
    "\xC7" => "\xE7", # LATIN LETTER E WITH MACRON
    "\xC8" => "\xE8", # LATIN LETTER C WITH CARON
    "\xC9" => "\xE9", # LATIN LETTER E WITH ACUTE
    "\xCA" => "\xEA", # LATIN LETTER Z WITH ACUTE
    "\xCB" => "\xEB", # LATIN LETTER E WITH DOT ABOVE
    "\xCC" => "\xEC", # LATIN LETTER G WITH CEDILLA
    "\xCD" => "\xED", # LATIN LETTER K WITH CEDILLA
    "\xCE" => "\xEE", # LATIN LETTER I WITH MACRON
    "\xCF" => "\xEF", # LATIN LETTER L WITH CEDILLA
    "\xD0" => "\xF0", # LATIN LETTER S WITH CARON
    "\xD1" => "\xF1", # LATIN LETTER N WITH ACUTE
    "\xD2" => "\xF2", # LATIN LETTER N WITH CEDILLA
    "\xD3" => "\xF3", # LATIN LETTER O WITH ACUTE
    "\xD4" => "\xF4", # LATIN LETTER O WITH MACRON
    "\xD5" => "\xF5", # LATIN LETTER O WITH TILDE
    "\xD6" => "\xF6", # LATIN LETTER O WITH DIAERESIS
    "\xD8" => "\xF8", # LATIN LETTER U WITH OGONEK
    "\xD9" => "\xF9", # LATIN LETTER L WITH STROKE
    "\xDA" => "\xFA", # LATIN LETTER S WITH ACUTE
    "\xDB" => "\xFB", # LATIN LETTER U WITH MACRON
    "\xDC" => "\xFC", # LATIN LETTER U WITH DIAERESIS
    "\xDD" => "\xFD", # LATIN LETTER Z WITH DOT ABOVE
    "\xDE" => "\xFE", # LATIN LETTER Z WITH CARON
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
