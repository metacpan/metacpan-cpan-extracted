# encoding: Cyrillic
# This file is encoded in Cyrillic.
die "This file is not encoded in Cyrillic.\n" if q{ } ne "\x82\xa0";

use strict;
use Cyrillic;

my $__FILE__ = __FILE__;

my %uc = ();
@uc{qw(a b c d e f g h i j k l m n o p q r s t u v w x y z)} =
    qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z);
%uc = (%uc,
    "\xD0" => "\xB0", # CYRILLIC LETTER A
    "\xD1" => "\xB1", # CYRILLIC LETTER BE
    "\xD2" => "\xB2", # CYRILLIC LETTER VE
    "\xD3" => "\xB3", # CYRILLIC LETTER GHE
    "\xD4" => "\xB4", # CYRILLIC LETTER DE
    "\xD5" => "\xB5", # CYRILLIC LETTER IE
    "\xD6" => "\xB6", # CYRILLIC LETTER ZHE
    "\xD7" => "\xB7", # CYRILLIC LETTER ZE
    "\xD8" => "\xB8", # CYRILLIC LETTER I
    "\xD9" => "\xB9", # CYRILLIC LETTER SHORT I
    "\xDA" => "\xBA", # CYRILLIC LETTER KA
    "\xDB" => "\xBB", # CYRILLIC LETTER EL
    "\xDC" => "\xBC", # CYRILLIC LETTER EM
    "\xDD" => "\xBD", # CYRILLIC LETTER EN
    "\xDE" => "\xBE", # CYRILLIC LETTER O
    "\xDF" => "\xBF", # CYRILLIC LETTER PE
    "\xE0" => "\xC0", # CYRILLIC LETTER ER
    "\xE1" => "\xC1", # CYRILLIC LETTER ES
    "\xE2" => "\xC2", # CYRILLIC LETTER TE
    "\xE3" => "\xC3", # CYRILLIC LETTER U
    "\xE4" => "\xC4", # CYRILLIC LETTER EF
    "\xE5" => "\xC5", # CYRILLIC LETTER HA
    "\xE6" => "\xC6", # CYRILLIC LETTER TSE
    "\xE7" => "\xC7", # CYRILLIC LETTER CHE
    "\xE8" => "\xC8", # CYRILLIC LETTER SHA
    "\xE9" => "\xC9", # CYRILLIC LETTER SHCHA
    "\xEA" => "\xCA", # CYRILLIC LETTER HARD SIGN
    "\xEB" => "\xCB", # CYRILLIC LETTER YERU
    "\xEC" => "\xCC", # CYRILLIC LETTER SOFT SIGN
    "\xED" => "\xCD", # CYRILLIC LETTER E
    "\xEE" => "\xCE", # CYRILLIC LETTER YU
    "\xEF" => "\xCF", # CYRILLIC LETTER YA
    "\xF1" => "\xA1", # CYRILLIC LETTER IO
    "\xF2" => "\xA2", # CYRILLIC LETTER DJE
    "\xF3" => "\xA3", # CYRILLIC LETTER GJE
    "\xF4" => "\xA4", # CYRILLIC LETTER UKRAINIAN IE
    "\xF5" => "\xA5", # CYRILLIC LETTER DZE
    "\xF6" => "\xA6", # CYRILLIC LETTER BYELORUSSIAN-UKRAINIAN I
    "\xF7" => "\xA7", # CYRILLIC LETTER YI
    "\xF8" => "\xA8", # CYRILLIC LETTER JE
    "\xF9" => "\xA9", # CYRILLIC LETTER LJE
    "\xFA" => "\xAA", # CYRILLIC LETTER NJE
    "\xFB" => "\xAB", # CYRILLIC LETTER TSHE
    "\xFC" => "\xAC", # CYRILLIC LETTER KJE
    "\xFE" => "\xAE", # CYRILLIC LETTER SHORT U
    "\xFF" => "\xAF", # CYRILLIC LETTER DZHE
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
