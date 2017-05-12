# encoding: Greek
# This file is encoded in Greek.
die "This file is not encoded in Greek.\n" if q{ } ne "\x82\xa0";

use strict;
use Greek;

my $__FILE__ = __FILE__;

my %lc = ();
@lc{qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)} =
    qw(a b c d e f g h i j k l m n o p q r s t u v w x y z);
%lc = (%lc,
    "\xB6" => "\xDC", # GREEK LETTER ALPHA WITH TONOS
    "\xB8" => "\xDD", # GREEK LETTER EPSILON WITH TONOS
    "\xB9" => "\xDE", # GREEK LETTER ETA WITH TONOS
    "\xBA" => "\xDF", # GREEK LETTER IOTA WITH TONOS
    "\xBC" => "\xFC", # GREEK LETTER OMICRON WITH TONOS
    "\xBE" => "\xFD", # GREEK LETTER UPSILON WITH TONOS
    "\xBF" => "\xFE", # GREEK LETTER OMEGA WITH TONOS
    "\xC1" => "\xE1", # GREEK LETTER ALPHA
    "\xC2" => "\xE2", # GREEK LETTER BETA
    "\xC3" => "\xE3", # GREEK LETTER GAMMA
    "\xC4" => "\xE4", # GREEK LETTER DELTA
    "\xC5" => "\xE5", # GREEK LETTER EPSILON
    "\xC6" => "\xE6", # GREEK LETTER ZETA
    "\xC7" => "\xE7", # GREEK LETTER ETA
    "\xC8" => "\xE8", # GREEK LETTER THETA
    "\xC9" => "\xE9", # GREEK LETTER IOTA
    "\xCA" => "\xEA", # GREEK LETTER KAPPA
    "\xCB" => "\xEB", # GREEK LETTER LAMDA
    "\xCC" => "\xEC", # GREEK LETTER MU
    "\xCD" => "\xED", # GREEK LETTER NU
    "\xCE" => "\xEE", # GREEK LETTER XI
    "\xCF" => "\xEF", # GREEK LETTER OMICRON
    "\xD0" => "\xF0", # GREEK LETTER PI
    "\xD1" => "\xF1", # GREEK LETTER RHO
    "\xD3" => "\xF3", # GREEK LETTER SIGMA
    "\xD4" => "\xF4", # GREEK LETTER TAU
    "\xD5" => "\xF5", # GREEK LETTER UPSILON
    "\xD6" => "\xF6", # GREEK LETTER PHI
    "\xD7" => "\xF7", # GREEK LETTER CHI
    "\xD8" => "\xF8", # GREEK LETTER PSI
    "\xD9" => "\xF9", # GREEK LETTER OMEGA
    "\xDA" => "\xFA", # GREEK LETTER IOTA WITH DIALYTIKA
    "\xDB" => "\xFB", # GREEK LETTER UPSILON WITH DIALYTIKA
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
