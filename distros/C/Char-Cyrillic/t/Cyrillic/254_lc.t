# encoding: Cyrillic
# This file is encoded in Cyrillic.
die "This file is not encoded in Cyrillic.\n" if q{ } ne "\x82\xa0";

use strict;
use Cyrillic;

my $__FILE__ = __FILE__;

my %lc = ();
@lc{qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)} =
    qw(a b c d e f g h i j k l m n o p q r s t u v w x y z);
%lc = (%lc,
    "\xA1" => "\xF1", # CYRILLIC LETTER IO
    "\xA2" => "\xF2", # CYRILLIC LETTER DJE
    "\xA3" => "\xF3", # CYRILLIC LETTER GJE
    "\xA4" => "\xF4", # CYRILLIC LETTER UKRAINIAN IE
    "\xA5" => "\xF5", # CYRILLIC LETTER DZE
    "\xA6" => "\xF6", # CYRILLIC LETTER BYELORUSSIAN-UKRAINIAN I
    "\xA7" => "\xF7", # CYRILLIC LETTER YI
    "\xA8" => "\xF8", # CYRILLIC LETTER JE
    "\xA9" => "\xF9", # CYRILLIC LETTER LJE
    "\xAA" => "\xFA", # CYRILLIC LETTER NJE
    "\xAB" => "\xFB", # CYRILLIC LETTER TSHE
    "\xAC" => "\xFC", # CYRILLIC LETTER KJE
    "\xAE" => "\xFE", # CYRILLIC LETTER SHORT U
    "\xAF" => "\xFF", # CYRILLIC LETTER DZHE
    "\xB0" => "\xD0", # CYRILLIC LETTER A
    "\xB1" => "\xD1", # CYRILLIC LETTER BE
    "\xB2" => "\xD2", # CYRILLIC LETTER VE
    "\xB3" => "\xD3", # CYRILLIC LETTER GHE
    "\xB4" => "\xD4", # CYRILLIC LETTER DE
    "\xB5" => "\xD5", # CYRILLIC LETTER IE
    "\xB6" => "\xD6", # CYRILLIC LETTER ZHE
    "\xB7" => "\xD7", # CYRILLIC LETTER ZE
    "\xB8" => "\xD8", # CYRILLIC LETTER I
    "\xB9" => "\xD9", # CYRILLIC LETTER SHORT I
    "\xBA" => "\xDA", # CYRILLIC LETTER KA
    "\xBB" => "\xDB", # CYRILLIC LETTER EL
    "\xBC" => "\xDC", # CYRILLIC LETTER EM
    "\xBD" => "\xDD", # CYRILLIC LETTER EN
    "\xBE" => "\xDE", # CYRILLIC LETTER O
    "\xBF" => "\xDF", # CYRILLIC LETTER PE
    "\xC0" => "\xE0", # CYRILLIC LETTER ER
    "\xC1" => "\xE1", # CYRILLIC LETTER ES
    "\xC2" => "\xE2", # CYRILLIC LETTER TE
    "\xC3" => "\xE3", # CYRILLIC LETTER U
    "\xC4" => "\xE4", # CYRILLIC LETTER EF
    "\xC5" => "\xE5", # CYRILLIC LETTER HA
    "\xC6" => "\xE6", # CYRILLIC LETTER TSE
    "\xC7" => "\xE7", # CYRILLIC LETTER CHE
    "\xC8" => "\xE8", # CYRILLIC LETTER SHA
    "\xC9" => "\xE9", # CYRILLIC LETTER SHCHA
    "\xCA" => "\xEA", # CYRILLIC LETTER HARD SIGN
    "\xCB" => "\xEB", # CYRILLIC LETTER YERU
    "\xCC" => "\xEC", # CYRILLIC LETTER SOFT SIGN
    "\xCD" => "\xED", # CYRILLIC LETTER E
    "\xCE" => "\xEE", # CYRILLIC LETTER YU
    "\xCF" => "\xEF", # CYRILLIC LETTER YA
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
