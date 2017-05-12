# encoding: KOI8U
# This file is encoded in KOI8-U.
die "This file is not encoded in KOI8-U.\n" if q{‚ } ne "\x82\xa0";

use strict;
use KOI8U;

my $__FILE__ = __FILE__;

my %lc = ();
@lc{qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)} =
    qw(a b c d e f g h i j k l m n o p q r s t u v w x y z);
%lc = (%lc,
    "\xB3" => "\xA3", # CYRILLIC LETTER IO
    "\xB4" => "\xA4", # CYRILLIC LETTER UKRAINIAN IE
    "\xB6" => "\xA6", # CYRILLIC LETTER BYELORUSSIAN-UKRAINIAN I
    "\xB7" => "\xA7", # CYRILLIC LETTER YI (UKRAINIAN)
    "\xBD" => "\xAD", # CYRILLIC LETTER GHE WITH UPTURN
    "\xE0" => "\xC0", # CYRILLIC LETTER YU
    "\xE1" => "\xC1", # CYRILLIC LETTER A
    "\xE2" => "\xC2", # CYRILLIC LETTER BE
    "\xE3" => "\xC3", # CYRILLIC LETTER TSE
    "\xE4" => "\xC4", # CYRILLIC LETTER DE
    "\xE5" => "\xC5", # CYRILLIC LETTER IE
    "\xE6" => "\xC6", # CYRILLIC LETTER EF
    "\xE7" => "\xC7", # CYRILLIC LETTER GHE
    "\xE8" => "\xC8", # CYRILLIC LETTER KHA
    "\xE9" => "\xC9", # CYRILLIC LETTER I
    "\xEA" => "\xCA", # CYRILLIC LETTER SHORT I
    "\xEB" => "\xCB", # CYRILLIC LETTER KA
    "\xEC" => "\xCC", # CYRILLIC LETTER EL
    "\xED" => "\xCD", # CYRILLIC LETTER EM
    "\xEE" => "\xCE", # CYRILLIC LETTER EN
    "\xEF" => "\xCF", # CYRILLIC LETTER O
    "\xF0" => "\xD0", # CYRILLIC LETTER PE
    "\xF1" => "\xD1", # CYRILLIC LETTER YA
    "\xF2" => "\xD2", # CYRILLIC LETTER ER
    "\xF3" => "\xD3", # CYRILLIC LETTER ES
    "\xF4" => "\xD4", # CYRILLIC LETTER TE
    "\xF5" => "\xD5", # CYRILLIC LETTER U
    "\xF6" => "\xD6", # CYRILLIC LETTER ZHE
    "\xF7" => "\xD7", # CYRILLIC LETTER VE
    "\xF8" => "\xD8", # CYRILLIC LETTER SOFT SIGN
    "\xF9" => "\xD9", # CYRILLIC LETTER YERU
    "\xFA" => "\xDA", # CYRILLIC LETTER ZE
    "\xFB" => "\xDB", # CYRILLIC LETTER SHA
    "\xFC" => "\xDC", # CYRILLIC LETTER E
    "\xFD" => "\xDD", # CYRILLIC LETTER SHCHA
    "\xFE" => "\xDE", # CYRILLIC LETTER CHE
    "\xFF" => "\xDF", # CYRILLIC LETTER HARD SIGN
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
