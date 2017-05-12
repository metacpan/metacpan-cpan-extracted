# encoding: Cyrillic
# This file is encoded in Cyrillic.
die "This file is not encoded in Cyrillic.\n" if q{ } ne "\x82\xa0";

use Cyrillic;
print "1..30\n";

if (fc('ABCDEF') eq fc('abcdef')) {
    print qq{ok - 1 fc('ABCDEF') eq fc('abcdef')\n};
}
else {
    print qq{not ok - 1 fc('ABCDEF') eq fc('abcdef')\n};
}

if ("\FABCDEF\E" eq "\Fabcdef\E") {
    print qq{ok - 2 "\\FABCDEF\\E" eq "\\Fabcdef\\E"\n};
}
else {
    print qq{not ok - 2 "\\FABCDEF\\E" eq "\\Fabcdef\\E"\n};
}

if ("\FABCDEF\E" =~ /\Fabcdef\E/) {
    print qq{ok - 3 "\\FABCDEF\\E" =~ /\\Fabcdef\\E/\n};
}
else {
    print qq{not ok - 3 "\\FABCDEF\\E" =~ /\\Fabcdef\\E/\n};
}

if ("\Fabcdef\E" =~ /\FABCDEF\E/) {
    print qq{ok - 4 "\\Fabcdef\\E" =~ /\\FABCDEF\\E/\n};
}
else {
    print qq{not ok - 4 "\\Fabcdef\\E" =~ /\\FABCDEF\\E/\n};
}

if ("\FABCDEF\E" =~ /\Fabcdef\E/i) {
    print qq{ok - 5 "\\FABCDEF\\E" =~ /\\Fabcdef\\E/i\n};
}
else {
    print qq{not ok - 5 "\\FABCDEF\\E" =~ /\\Fabcdef\\E/i\n};
}

if ("\Fabcdef\E" =~ /\FABCDEF\E/i) {
    print qq{ok - 6 "\\Fabcdef\\E" =~ /\\FABCDEF\\E/i\n};
}
else {
    print qq{not ok - 6 "\\Fabcdef\\E" =~ /\\FABCDEF\\E/i\n};
}

my $var = 'abcdef';
if ("\FABCDEF\E" =~ /\F$var\E/i) {
    print qq{ok - 7 "\\FABCDEF\\E" =~ /\\F\$var\\E/i\n};
}
else {
    print qq{not ok - 7 "\\FABCDEF\\E" =~ /\\F\$var\\E/i\n};
}

$var = 'ABCDEF';
if ("\Fabcdef\E" =~ /\F$var\E/i) {
    print qq{ok - 8 "\\Fabcdef\\E" =~ /\\F\$var\\E/i\n};
}
else {
    print qq{not ok - 8 "\\Fabcdef\\E" =~ /\\F\$var\\E/i\n};
}

my %fc = ();
@fc{qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z)} =
    qw(a b c d e f g h i j k l m n o p q r s t u v w x y z);
%fc = (%fc,
    "\xA1" => "\xF1",     # CYRILLIC CAPITAL LETTER IO --> CYRILLIC SMALL LETTER IO
    "\xA2" => "\xF2",     # CYRILLIC CAPITAL LETTER DJE --> CYRILLIC SMALL LETTER DJE
    "\xA3" => "\xF3",     # CYRILLIC CAPITAL LETTER GJE --> CYRILLIC SMALL LETTER GJE
    "\xA4" => "\xF4",     # CYRILLIC CAPITAL LETTER UKRAINIAN IE --> CYRILLIC SMALL LETTER UKRAINIAN IE
    "\xA5" => "\xF5",     # CYRILLIC CAPITAL LETTER DZE --> CYRILLIC SMALL LETTER DZE
    "\xA6" => "\xF6",     # CYRILLIC CAPITAL LETTER BYELORUSSIAN-UKRAINIAN I --> CYRILLIC SMALL LETTER BYELORUSSIAN-UKRAINIAN I
    "\xA7" => "\xF7",     # CYRILLIC CAPITAL LETTER YI --> CYRILLIC SMALL LETTER YI
    "\xA8" => "\xF8",     # CYRILLIC CAPITAL LETTER JE --> CYRILLIC SMALL LETTER JE
    "\xA9" => "\xF9",     # CYRILLIC CAPITAL LETTER LJE --> CYRILLIC SMALL LETTER LJE
    "\xAA" => "\xFA",     # CYRILLIC CAPITAL LETTER NJE --> CYRILLIC SMALL LETTER NJE
    "\xAB" => "\xFB",     # CYRILLIC CAPITAL LETTER TSHE --> CYRILLIC SMALL LETTER TSHE
    "\xAC" => "\xFC",     # CYRILLIC CAPITAL LETTER KJE --> CYRILLIC SMALL LETTER KJE
    "\xAE" => "\xFE",     # CYRILLIC CAPITAL LETTER SHORT U --> CYRILLIC SMALL LETTER SHORT U
    "\xAF" => "\xFF",     # CYRILLIC CAPITAL LETTER DZHE --> CYRILLIC SMALL LETTER DZHE
    "\xB0" => "\xD0",     # CYRILLIC CAPITAL LETTER A --> CYRILLIC SMALL LETTER A
    "\xB1" => "\xD1",     # CYRILLIC CAPITAL LETTER BE --> CYRILLIC SMALL LETTER BE
    "\xB2" => "\xD2",     # CYRILLIC CAPITAL LETTER VE --> CYRILLIC SMALL LETTER VE
    "\xB3" => "\xD3",     # CYRILLIC CAPITAL LETTER GHE --> CYRILLIC SMALL LETTER GHE
    "\xB4" => "\xD4",     # CYRILLIC CAPITAL LETTER DE --> CYRILLIC SMALL LETTER DE
    "\xB5" => "\xD5",     # CYRILLIC CAPITAL LETTER IE --> CYRILLIC SMALL LETTER IE
    "\xB6" => "\xD6",     # CYRILLIC CAPITAL LETTER ZHE --> CYRILLIC SMALL LETTER ZHE
    "\xB7" => "\xD7",     # CYRILLIC CAPITAL LETTER ZE --> CYRILLIC SMALL LETTER ZE
    "\xB8" => "\xD8",     # CYRILLIC CAPITAL LETTER I --> CYRILLIC SMALL LETTER I
    "\xB9" => "\xD9",     # CYRILLIC CAPITAL LETTER SHORT I --> CYRILLIC SMALL LETTER SHORT I
    "\xBA" => "\xDA",     # CYRILLIC CAPITAL LETTER KA --> CYRILLIC SMALL LETTER KA
    "\xBB" => "\xDB",     # CYRILLIC CAPITAL LETTER EL --> CYRILLIC SMALL LETTER EL
    "\xBC" => "\xDC",     # CYRILLIC CAPITAL LETTER EM --> CYRILLIC SMALL LETTER EM
    "\xBD" => "\xDD",     # CYRILLIC CAPITAL LETTER EN --> CYRILLIC SMALL LETTER EN
    "\xBE" => "\xDE",     # CYRILLIC CAPITAL LETTER O --> CYRILLIC SMALL LETTER O
    "\xBF" => "\xDF",     # CYRILLIC CAPITAL LETTER PE --> CYRILLIC SMALL LETTER PE
    "\xC0" => "\xE0",     # CYRILLIC CAPITAL LETTER ER --> CYRILLIC SMALL LETTER ER
    "\xC1" => "\xE1",     # CYRILLIC CAPITAL LETTER ES --> CYRILLIC SMALL LETTER ES
    "\xC2" => "\xE2",     # CYRILLIC CAPITAL LETTER TE --> CYRILLIC SMALL LETTER TE
    "\xC3" => "\xE3",     # CYRILLIC CAPITAL LETTER U --> CYRILLIC SMALL LETTER U
    "\xC4" => "\xE4",     # CYRILLIC CAPITAL LETTER EF --> CYRILLIC SMALL LETTER EF
    "\xC5" => "\xE5",     # CYRILLIC CAPITAL LETTER HA --> CYRILLIC SMALL LETTER HA
    "\xC6" => "\xE6",     # CYRILLIC CAPITAL LETTER TSE --> CYRILLIC SMALL LETTER TSE
    "\xC7" => "\xE7",     # CYRILLIC CAPITAL LETTER CHE --> CYRILLIC SMALL LETTER CHE
    "\xC8" => "\xE8",     # CYRILLIC CAPITAL LETTER SHA --> CYRILLIC SMALL LETTER SHA
    "\xC9" => "\xE9",     # CYRILLIC CAPITAL LETTER SHCHA --> CYRILLIC SMALL LETTER SHCHA
    "\xCA" => "\xEA",     # CYRILLIC CAPITAL LETTER HARD SIGN --> CYRILLIC SMALL LETTER HARD SIGN
    "\xCB" => "\xEB",     # CYRILLIC CAPITAL LETTER YERU --> CYRILLIC SMALL LETTER YERU
    "\xCC" => "\xEC",     # CYRILLIC CAPITAL LETTER SOFT SIGN --> CYRILLIC SMALL LETTER SOFT SIGN
    "\xCD" => "\xED",     # CYRILLIC CAPITAL LETTER E --> CYRILLIC SMALL LETTER E
    "\xCE" => "\xEE",     # CYRILLIC CAPITAL LETTER YU --> CYRILLIC SMALL LETTER YU
    "\xCF" => "\xEF",     # CYRILLIC CAPITAL LETTER YA --> CYRILLIC SMALL LETTER YA
);
my $before_fc = join "\t",               sort keys %fc;
my $after_fc  = join "\t", map {$fc{$_}} sort keys %fc;

if (fc("$before_fc") eq "$after_fc") {
    print qq{ok - 9 fc("\$before_fc") eq "\$after_fc"\n};
}
else {
    print qq{not ok - 9 fc("\$before_fc") eq "\$after_fc"\n};
}

if (fc("$after_fc") eq "$after_fc") {
    print qq{ok - 10 fc("\$after_fc") eq "\$after_fc"\n};
}
else {
    print qq{not ok - 10 fc("\$after_fc") eq "\$after_fc"\n};
}

if (fc("$before_fc") eq fc("$after_fc")) {
    print qq{ok - 11 fc("\$before_fc") eq fc("\$after_fc")\n};
}
else {
    print qq{not ok - 11 fc("\$before_fc") eq fc("\$after_fc")\n};
}

if ("\F$before_fc\E" eq "$after_fc") {
    print qq{ok - 12 "\\F\$before_fc\\E" eq "\$after_fc"\n};
}
else {
    print qq{not ok - 12 "\\F\$before_fc\\E" eq "\$after_fc"\n};
}

if ("\F$after_fc\E" eq "$after_fc") {
    print qq{ok - 13 "\\F\$after_fc\\E" eq "\$after_fc"\n};
}
else {
    print qq{not ok - 13 "\\F\$after_fc\\E" eq "\$after_fc"\n};
}

if ("\F$before_fc\E" eq "\F$after_fc\E") {
    print qq{ok - 14 "\\F\$before_fc\\E" eq "\\F\$after_fc\\E"\n};
}
else {
    print qq{not ok - 14 "\\F\$before_fc\\E" eq "\\F\$after_fc\\E"\n};
}

if ("$after_fc" =~ /\F$before_fc\E/) {
    print qq{ok - 15 "\$after_fc" =~ /\\F\$before_fc\\E/\n};
}
else {
    print qq{not ok - 15 "\$after_fc" =~ /\\F\$before_fc\\E/\n};
}

if ("$after_fc" =~ /\F$after_fc\E/) {
    print qq{ok - 16 "\$after_fc" =~ /\\F\$after_fc\\E/\n};
}
else {
    print qq{not ok - 16 "\$after_fc" =~ /\\F\$after_fc\\E/\n};
}

if ("\F$before_fc\E" =~ /$after_fc/) {
    print qq{ok - 17 "\\F\$before_fc\\E" =~ /\$after_fc/\n};
}
else {
    print qq{not ok - 17 "\\F\$before_fc\\E" =~ /\$after_fc/\n};
}

if ("\F$before_fc\E" =~ /\F$before_fc\E/) {
    print qq{ok - 18 "\\F\$before_fc\\E" =~ /\\F\$before_fc\\E/\n};
}
else {
    print qq{not ok - 18 "\\F\$before_fc\\E" =~ /\\F\$before_fc\\E/\n};
}

if ("\F$before_fc\E" =~ /\F$after_fc\E/) {
    print qq{ok - 19 "\\F\$before_fc\\E" =~ /\\F\$after_fc\\E/\n};
}
else {
    print qq{not ok - 19 "\\F\$before_fc\\E" =~ /\\F\$after_fc\\E/\n};
}

if ("\F$after_fc\E" =~ /$after_fc/) {
    print qq{ok - 20 "\\F\$after_fc\\E" =~ /\$after_fc/\n};
}
else {
    print qq{not ok - 20 "\\F\$after_fc\\E" =~ /\$after_fc/\n};
}

if ("\F$after_fc\E" =~ /\F$before_fc\E/) {
    print qq{ok - 21 "\\F\$after_fc\\E" =~ /\\F\$before_fc\\E/\n};
}
else {
    print qq{not ok - 21 "\\F\$after_fc\\E" =~ /\\F\$before_fc\\E/\n};
}

if ("\F$after_fc\E" =~ /\F$after_fc\E/) {
    print qq{ok - 22 "\\F\$after_fc\\E" =~ /\\F\$after_fc\\E/\n};
}
else {
    print qq{not ok - 22 "\\F\$after_fc\\E" =~ /\\F\$after_fc\\E/\n};
}

if ("$after_fc" =~ /\F$before_fc\E/i) {
    print qq{ok - 23 "\$after_fc" =~ /\\F\$before_fc\\E/i\n};
}
else {
    print qq{not ok - 23 "\$after_fc" =~ /\\F\$before_fc\\E/i\n};
}

if ("$after_fc" =~ /\F$after_fc\E/i) {
    print qq{ok - 24 "\$after_fc" =~ /\\F\$after_fc\\E/i\n};
}
else {
    print qq{not ok - 24 "\$after_fc" =~ /\\F\$after_fc\\E/i\n};
}

if ("\F$before_fc\E" =~ /$after_fc/i) {
    print qq{ok - 25 "\\F\$before_fc\\E" =~ /\$after_fc/i\n};
}
else {
    print qq{not ok - 25 "\\F\$before_fc\\E" =~ /\$after_fc/i\n};
}

if ("\F$before_fc\E" =~ /\F$before_fc\E/i) {
    print qq{ok - 26 "\\F\$before_fc\\E" =~ /\\F\$before_fc\\E/i\n};
}
else {
    print qq{not ok - 26 "\\F\$before_fc\\E" =~ /\\F\$before_fc\\E/i\n};
}

if ("\F$before_fc\E" =~ /\F$after_fc\E/i) {
    print qq{ok - 27 "\\F\$before_fc\\E" =~ /\\F\$after_fc\\E/i\n};
}
else {
    print qq{not ok - 27 "\\F\$before_fc\\E" =~ /\\F\$after_fc\\E/i\n};
}

if ("\F$after_fc\E" =~ /$after_fc/i) {
    print qq{ok - 28 "\\F\$after_fc\\E" =~ /\$after_fc/i\n};
}
else {
    print qq{not ok - 28 "\\F\$after_fc\\E" =~ /\$after_fc/i\n};
}

if ("\F$after_fc\E" =~ /\F$before_fc\E/i) {
    print qq{ok - 29 "\\F\$after_fc\\E" =~ /\\F\$before_fc\\E/i\n};
}
else {
    print qq{not ok - 29 "\\F\$after_fc\\E" =~ /\\F\$before_fc\\E/i\n};
}

if ("\F$after_fc\E" =~ /\F$after_fc\E/i) {
    print qq{ok - 30 "\\F\$after_fc\\E" =~ /\\F\$after_fc\\E/i\n};
}
else {
    print qq{not ok - 30 "\\F\$after_fc\\E" =~ /\\F\$after_fc\\E/i\n};
}

__END__

