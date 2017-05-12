# encoding: Latin2
# This file is encoded in Latin-2.
die "This file is not encoded in Latin-2.\n" if q{ } ne "\x82\xa0";

use Latin2;
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
    "\xA1" => "\xB1",     # LATIN CAPITAL LETTER A WITH OGONEK --> LATIN SMALL LETTER A WITH OGONEK
    "\xA3" => "\xB3",     # LATIN CAPITAL LETTER L WITH STROKE --> LATIN SMALL LETTER L WITH STROKE
    "\xA5" => "\xB5",     # LATIN CAPITAL LETTER L WITH CARON --> LATIN SMALL LETTER L WITH CARON
    "\xA6" => "\xB6",     # LATIN CAPITAL LETTER S WITH ACUTE --> LATIN SMALL LETTER S WITH ACUTE
    "\xA9" => "\xB9",     # LATIN CAPITAL LETTER S WITH CARON --> LATIN SMALL LETTER S WITH CARON
    "\xAA" => "\xBA",     # LATIN CAPITAL LETTER S WITH CEDILLA --> LATIN SMALL LETTER S WITH CEDILLA
    "\xAB" => "\xBB",     # LATIN CAPITAL LETTER T WITH CARON --> LATIN SMALL LETTER T WITH CARON
    "\xAC" => "\xBC",     # LATIN CAPITAL LETTER Z WITH ACUTE --> LATIN SMALL LETTER Z WITH ACUTE
    "\xAE" => "\xBE",     # LATIN CAPITAL LETTER Z WITH CARON --> LATIN SMALL LETTER Z WITH CARON
    "\xAF" => "\xBF",     # LATIN CAPITAL LETTER Z WITH DOT ABOVE --> LATIN SMALL LETTER Z WITH DOT ABOVE
    "\xC0" => "\xE0",     # LATIN CAPITAL LETTER R WITH ACUTE --> LATIN SMALL LETTER R WITH ACUTE
    "\xC1" => "\xE1",     # LATIN CAPITAL LETTER A WITH ACUTE --> LATIN SMALL LETTER A WITH ACUTE
    "\xC2" => "\xE2",     # LATIN CAPITAL LETTER A WITH CIRCUMFLEX --> LATIN SMALL LETTER A WITH CIRCUMFLEX
    "\xC3" => "\xE3",     # LATIN CAPITAL LETTER A WITH BREVE --> LATIN SMALL LETTER A WITH BREVE
    "\xC4" => "\xE4",     # LATIN CAPITAL LETTER A WITH DIAERESIS --> LATIN SMALL LETTER A WITH DIAERESIS
    "\xC5" => "\xE5",     # LATIN CAPITAL LETTER L WITH ACUTE --> LATIN SMALL LETTER L WITH ACUTE
    "\xC6" => "\xE6",     # LATIN CAPITAL LETTER C WITH ACUTE --> LATIN SMALL LETTER C WITH ACUTE
    "\xC7" => "\xE7",     # LATIN CAPITAL LETTER C WITH CEDILLA --> LATIN SMALL LETTER C WITH CEDILLA
    "\xC8" => "\xE8",     # LATIN CAPITAL LETTER C WITH CARON --> LATIN SMALL LETTER C WITH CARON
    "\xC9" => "\xE9",     # LATIN CAPITAL LETTER E WITH ACUTE --> LATIN SMALL LETTER E WITH ACUTE
    "\xCA" => "\xEA",     # LATIN CAPITAL LETTER E WITH OGONEK --> LATIN SMALL LETTER E WITH OGONEK
    "\xCB" => "\xEB",     # LATIN CAPITAL LETTER E WITH DIAERESIS --> LATIN SMALL LETTER E WITH DIAERESIS
    "\xCC" => "\xEC",     # LATIN CAPITAL LETTER E WITH CARON --> LATIN SMALL LETTER E WITH CARON
    "\xCD" => "\xED",     # LATIN CAPITAL LETTER I WITH ACUTE --> LATIN SMALL LETTER I WITH ACUTE
    "\xCE" => "\xEE",     # LATIN CAPITAL LETTER I WITH CIRCUMFLEX --> LATIN SMALL LETTER I WITH CIRCUMFLEX
    "\xCF" => "\xEF",     # LATIN CAPITAL LETTER D WITH CARON --> LATIN SMALL LETTER D WITH CARON
    "\xD0" => "\xF0",     # LATIN CAPITAL LETTER D WITH STROKE --> LATIN SMALL LETTER D WITH STROKE
    "\xD1" => "\xF1",     # LATIN CAPITAL LETTER N WITH ACUTE --> LATIN SMALL LETTER N WITH ACUTE
    "\xD2" => "\xF2",     # LATIN CAPITAL LETTER N WITH CARON --> LATIN SMALL LETTER N WITH CARON
    "\xD3" => "\xF3",     # LATIN CAPITAL LETTER O WITH ACUTE --> LATIN SMALL LETTER O WITH ACUTE
    "\xD4" => "\xF4",     # LATIN CAPITAL LETTER O WITH CIRCUMFLEX --> LATIN SMALL LETTER O WITH CIRCUMFLEX
    "\xD5" => "\xF5",     # LATIN CAPITAL LETTER O WITH DOUBLE ACUTE --> LATIN SMALL LETTER O WITH DOUBLE ACUTE
    "\xD6" => "\xF6",     # LATIN CAPITAL LETTER O WITH DIAERESIS --> LATIN SMALL LETTER O WITH DIAERESIS
    "\xD8" => "\xF8",     # LATIN CAPITAL LETTER R WITH CARON --> LATIN SMALL LETTER R WITH CARON
    "\xD9" => "\xF9",     # LATIN CAPITAL LETTER U WITH RING ABOVE --> LATIN SMALL LETTER U WITH RING ABOVE
    "\xDA" => "\xFA",     # LATIN CAPITAL LETTER U WITH ACUTE --> LATIN SMALL LETTER U WITH ACUTE
    "\xDB" => "\xFB",     # LATIN CAPITAL LETTER U WITH DOUBLE ACUTE --> LATIN SMALL LETTER U WITH DOUBLE ACUTE
    "\xDC" => "\xFC",     # LATIN CAPITAL LETTER U WITH DIAERESIS --> LATIN SMALL LETTER U WITH DIAERESIS
    "\xDD" => "\xFD",     # LATIN CAPITAL LETTER Y WITH ACUTE --> LATIN SMALL LETTER Y WITH ACUTE
    "\xDE" => "\xFE",     # LATIN CAPITAL LETTER T WITH CEDILLA --> LATIN SMALL LETTER T WITH CEDILLA
    "\xDF" => "\x73\x73", # LATIN SMALL LETTER SHARP S --> LATIN SMALL LETTER S, LATIN SMALL LETTER S
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

