# encoding: Latin7
# This file is encoded in Latin-7.
die "This file is not encoded in Latin-7.\n" if q{ } ne "\x82\xa0";

use strict;
use Latin7;

my $__FILE__ = __FILE__;

my %uc = ();
@uc{qw(a b c d e f g h i j k l m n o p q r s t u v w x y z)} =
    qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z);
%uc = (%uc,
    "\xB8" => "\xA8", # LATIN LETTER O WITH STROKE
    "\xBA" => "\xAA", # LATIN LETTER R WITH CEDILLA
    "\xBF" => "\xAF", # LATIN LETTER AE
    "\xE0" => "\xC0", # LATIN LETTER A WITH OGONEK
    "\xE1" => "\xC1", # LATIN LETTER I WITH OGONEK
    "\xE2" => "\xC2", # LATIN LETTER A WITH MACRON
    "\xE3" => "\xC3", # LATIN LETTER C WITH ACUTE
    "\xE4" => "\xC4", # LATIN LETTER A WITH DIAERESIS
    "\xE5" => "\xC5", # LATIN LETTER A WITH RING ABOVE
    "\xE6" => "\xC6", # LATIN LETTER E WITH OGONEK
    "\xE7" => "\xC7", # LATIN LETTER E WITH MACRON
    "\xE8" => "\xC8", # LATIN LETTER C WITH CARON
    "\xE9" => "\xC9", # LATIN LETTER E WITH ACUTE
    "\xEA" => "\xCA", # LATIN LETTER Z WITH ACUTE
    "\xEB" => "\xCB", # LATIN LETTER E WITH DOT ABOVE
    "\xEC" => "\xCC", # LATIN LETTER G WITH CEDILLA
    "\xED" => "\xCD", # LATIN LETTER K WITH CEDILLA
    "\xEE" => "\xCE", # LATIN LETTER I WITH MACRON
    "\xEF" => "\xCF", # LATIN LETTER L WITH CEDILLA
    "\xF0" => "\xD0", # LATIN LETTER S WITH CARON
    "\xF1" => "\xD1", # LATIN LETTER N WITH ACUTE
    "\xF2" => "\xD2", # LATIN LETTER N WITH CEDILLA
    "\xF3" => "\xD3", # LATIN LETTER O WITH ACUTE
    "\xF4" => "\xD4", # LATIN LETTER O WITH MACRON
    "\xF5" => "\xD5", # LATIN LETTER O WITH TILDE
    "\xF6" => "\xD6", # LATIN LETTER O WITH DIAERESIS
    "\xF8" => "\xD8", # LATIN LETTER U WITH OGONEK
    "\xF9" => "\xD9", # LATIN LETTER L WITH STROKE
    "\xFA" => "\xDA", # LATIN LETTER S WITH ACUTE
    "\xFB" => "\xDB", # LATIN LETTER U WITH MACRON
    "\xFC" => "\xDC", # LATIN LETTER U WITH DIAERESIS
    "\xFD" => "\xDD", # LATIN LETTER Z WITH DOT ABOVE
    "\xFE" => "\xDE", # LATIN LETTER Z WITH CARON
);

printf("1..%d\n", scalar(keys %uc));

my $tno = 1;
for my $char (sort keys %uc){
    if (uc($char) eq $uc{$char}) {
        printf(qq{ok - $tno uc("\\x%02X") eq "\\x%02X" $^X $__FILE__\n}, ord($char), ord($uc{$char}));
    }
    else {
        printf(qq{not ok - $tno uc("\\x%02X") eq "\\x%02X" $^X $__FILE__\n}, ord($char), ord($uc{$char}));
    }
    $tno++;
}

__END__
