#!perl
# Convert/Translit/example.pl  for testing Convert/Translit.pm
#  Genji Schmeder  <genji@community.net>  21 October 1997
if ($] < 5) {die "Perl version must be at least 5.\n";}
use strict;
use integer;

package test_probowac_pruefen;
my ($aa, $bb, $ebtolat, $ff, $from_charset, $gg);
my ($hh, $jj, $lattoeb, $to_charset, $vrbos, $xx, $yy, $zz,);
my (@apsub, @ebcdic_us_result, @latin2_original, @mm, @nn);

print scalar localtime; print "\n";
$from_charset = "Latin2";
$to_charset = "Ebcdic-US";
print "Convert from $from_charset to $to_charset and back:\n";

print "You can get verbose output by assigning the variable \"vrbos\".\n";
$vrbos = "";

$aa = q/Ów szybki czerwony lis bêdzie skaka³ nad ¶pi±cego pró¿niaczego br±zowego psa./;
print "Text is Polish for \"That quick red fox will be jumping over the sleeping lazy brown dog.\"\n";

@latin2_original = (
	0xD3,0x77,0x20,0x73,0x7A,0x79,0x62,0x6B,0x69,0x20,0x63,0x7A,0x65,0x72,0x77,0x6F,
	0x6E,0x79,0x20,0x6C,0x69,0x73,0x20,0x62,0xEA,0x64,0x7A,0x69,0x65,0x20,0x73,0x6B,
	0x61,0x6B,0x61,0xB3,0x20,0x6E,0x61,0x64,0x20,0xB6,0x70,0x69,0xB1,0x63,0x65,0x67,
	0x6F,0x20,0x70,0x72,0xF3,0xBF,0x6E,0x69,0x61,0x63,0x7A,0x65,0x67,0x6F,0x20,0x62,
	0x72,0xB1,0x7A,0x6F,0x77,0x65,0x67,0x6F,0x20,0x70,0x73,0x61,0x2E
);

$xx = pack ("C*", @latin2_original);
print "Original $from_charset text: $xx\n";
if ($aa ne $xx) {print "Not really same original.  Flawed test.\n";}

@ebcdic_us_result = (
	0xD6,0xA6,0x40,0xA2,0xA9,0xA8,0x82,0x92,0x89,0x40,0x83,0xA9,0x85,0x99,0xA6,0x96,
	0x95,0xA8,0x40,0x93,0x89,0xA2,0x40,0x82,0x85,0x84,0xA9,0x89,0x85,0x40,0xA2,0x92,
	0x81,0x92,0x81,0x93,0x40,0x95,0x81,0x84,0x40,0xA2,0x97,0x89,0x81,0x83,0x85,0x87,
	0x96,0x40,0x97,0x99,0x96,0xA9,0x95,0x89,0x81,0x83,0xA9,0x85,0x87,0x96,0x40,0x82,
	0x99,0x81,0xA9,0x96,0xA6,0x85,0x87,0x96,0x40,0x97,0xA2,0x81,0x4B
);

use Convert::Translit;
print "\nBuild transliteration map $from_charset to $to_charset by new():\n";
$lattoeb = new Convert::Translit( $from_charset, $to_charset, $vrbos);
$jj = 0;
for ( @{$lattoeb->{TRN_ARY}} ) {
	printf "%2.2X ", $_;
	if ( ! ((++$jj) % 16)) {print "\n";}
}
print "\nCall fully qualified subroutine to convert $from_charset text to $to_charset:\n";
$yy = Convert::Translit::transliterate($xx);
print "$to_charset text: $yy\n";
$bb = pack("C*", @ebcdic_us_result);
if ($bb ne $yy) {print "Unexpected $to_charset result.  Flawed test.\n";}

print "\nBuild transliteration map $to_charset to $from_charset by new():\n";
$ebtolat = new Convert::Translit( $to_charset, $from_charset, $vrbos);
$jj = 0;
for ( @{$ebtolat->{TRN_ARY}} ) {
	printf "%2.2X ", $_;
	if ( ! ((++$jj) % 16)) {print "\n";}
}
print "\nCall fully qualified subroutine to convert $to_charset text to $from_charset:\n";
$zz = Convert::Translit::transliterate($yy);
print "$from_charset text again: $zz\n";

print "\nCertain characters were irreversibly changed:\n";
@mm = unpack("C*", $yy);
@nn = unpack("C*", $zz);
for $jj (0 .. $#latin2_original) {
	$ff = $latin2_original[$jj];
	$gg = $mm[$jj];
	$hh = $nn[$jj];
	if ( $ff != $hh ) {
		printf "\"%1.1s\" (%2.2X) ==> \"%1.1s\" (%2.2X) ==> \"%1.1s\" (%2.2X)\n",
			pack("C", $ff), $ff, pack("C", $gg), $gg, pack("C", $hh), $hh;
	}
}

@apsub = (
	"D3==>D6	LATIN CAPITAL LETTER O WITH ACUTE==>LATIN CAPITAL LETTER O",
	"EA==>85	LATIN SMALL LETTER E WITH OGONEK==>LATIN SMALL LETTER E",
	"B3==>93	LATIN SMALL LETTER L WITH STROKE==>LATIN SMALL LETTER L",
	"B6==>A2	LATIN SMALL LETTER S WITH ACUTE==>LATIN SMALL LETTER S",
	"B1==>81	LATIN SMALL LETTER A WITH OGONEK==>LATIN SMALL LETTER A",
	"F3==>96	LATIN SMALL LETTER O WITH ACUTE==>LATIN SMALL LETTER O",
	"BF==>A9	LATIN SMALL LETTER Z WITH DOT ABOVE==>LATIN SMALL LETTER Z"
);
print "\nHere are approximate substitutions when converting $from_charset to $to_charset:\n";
for ( @apsub) { print "$_\n";}

print "\nCall as object:\n";
print "Original $from_charset text: $xx\n";
$yy = $lattoeb->transliterate($xx);
print "$to_charset text: $yy\n";
$zz = $ebtolat->transliterate($yy);
print "$from_charset text again: $zz\n";

print "\nDone\n";
exit;

__END__
Actual output of this script:
Mon Nov  3 16:28:25 1997
Convert from Latin2 to Ebcdic-US and back:
You can get verbose output by assigning the variable "vrbos".
Text is Polish for "That quick red fox will be jumping over the sleeping lazy brown dog."
Original Latin2 text: Ów szybki czerwony lis bêdzie skaka³ nad ¶pi±cego pró¿niaczego br±zowego psa.

Build transliteration map Latin2 to Ebcdic-US by new():
00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F 
10 11 12 13 14 15 16 17 18 19 1A 1B 1C 1D 1E 1F 
40 5A 7F 7B 5B 6C 50 7D 4D 5D 5C 4E 6B 60 4B 61 
F0 F1 F2 F3 F4 F5 F6 F7 F8 F9 7A 5E 4C 7E 6E 6F 
7C C1 C2 C3 C4 C5 C6 C7 C8 C9 D1 D2 D3 D4 D5 D6 
D7 D8 D9 E2 E3 E4 E5 E6 E7 E8 E9 4A E0 5F 6A 6D 
79 81 82 83 84 85 86 87 88 89 91 92 93 94 95 96 
97 98 99 A2 A3 A4 A5 A6 A7 A8 A9 C0 4F D0 A1 FF 
4A 4A 4A 4A 4A 4A 4A 4A 4A 4A 4A 4A 4A 4A 4A 4A 
4A 4A 4A 4A 4A 4A 4A 4A 4A 4A 4A 4A 4A 4A 4A 4A 
40 C1 4A D3 4A D3 E2 4A 4A E2 E2 E3 E9 4A E9 E9 
4A 81 4A 93 4A 93 A2 4A 4A A2 A2 A3 A9 4A A9 A9 
D9 C1 C1 C1 C1 D3 C3 C3 C3 C5 C5 C5 C5 C9 C9 C4 
C4 D5 D5 D6 D6 D6 D6 4A D9 E4 E4 E4 E4 E8 E3 4A 
99 81 81 81 81 93 83 83 83 85 85 85 85 89 89 84 
84 95 95 96 96 96 96 4A 99 A4 A4 A4 A4 A8 A3 4A 

Call fully qualified subroutine to convert Latin2 text to Ebcdic-US:
Ebcdic-US text: Ö¦@¢©¨‚’‰@ƒ©…™¦–•¨@“‰¢@‚…„©‰…@¢’’“@•„@¢—‰ƒ…‡–@—™–©•‰ƒ©…‡–@‚™©–¦…‡–@—¢K

Build transliteration map Ebcdic-US to Latin2 by new():
00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F 
10 11 12 13 14 15 16 17 18 19 1A 1B 1C 1D 1E 1F 
FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF 
FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF 
20 FF FF FF FF FF FF FF FF FF 5B 2E 3C 28 2B 7C 
26 FF FF FF FF FF FF FF FF FF 21 24 2A 29 3B 5D 
2D 2F FF FF FF FF FF FF FF FF 5E 2C 25 5F 3E 3F 
FF FF FF FF FF FF FF FF FF 60 3A 23 40 27 3D 22 
FF 61 62 63 64 65 66 67 68 69 FF FF FF FF FF FF 
FF 6A 6B 6C 6D 6E 6F 70 71 72 FF FF FF FF FF FF 
FF 7E 73 74 75 76 77 78 79 7A FF FF FF FF FF FF 
FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF FF 
7B 41 42 43 44 45 46 47 48 49 FF FF FF FF FF FF 
7D 4A 4B 4C 4D 4E 4F 50 51 52 FF FF FF FF FF FF 
5C FF 53 54 55 56 57 58 59 5A FF FF FF FF FF FF 
30 31 32 33 34 35 36 37 38 39 FF FF FF FF FF 7F 

Call fully qualified subroutine to convert Ebcdic-US text to Latin2:
Latin2 text again: Ow szybki czerwony lis bedzie skakal nad spiacego prozniaczego brazowego psa.

Certain characters were irreversibly changed:
"Ó" (D3) ==> "Ö" (D6) ==> "O" (4F)
"ê" (EA) ==> "…" (85) ==> "e" (65)
"³" (B3) ==> "“" (93) ==> "l" (6C)
"¶" (B6) ==> "¢" (A2) ==> "s" (73)
"±" (B1) ==> "" (81) ==> "a" (61)
"ó" (F3) ==> "–" (96) ==> "o" (6F)
"¿" (BF) ==> "©" (A9) ==> "z" (7A)
"±" (B1) ==> "" (81) ==> "a" (61)

Here are approximate substitutions when converting Latin2 to Ebcdic-US:
D3==>D6	LATIN CAPITAL LETTER O WITH ACUTE==>LATIN CAPITAL LETTER O
EA==>85	LATIN SMALL LETTER E WITH OGONEK==>LATIN SMALL LETTER E
B3==>93	LATIN SMALL LETTER L WITH STROKE==>LATIN SMALL LETTER L
B6==>A2	LATIN SMALL LETTER S WITH ACUTE==>LATIN SMALL LETTER S
B1==>81	LATIN SMALL LETTER A WITH OGONEK==>LATIN SMALL LETTER A
F3==>96	LATIN SMALL LETTER O WITH ACUTE==>LATIN SMALL LETTER O
BF==>A9	LATIN SMALL LETTER Z WITH DOT ABOVE==>LATIN SMALL LETTER Z

Call as object:
Original Latin2 text: Ów szybki czerwony lis bêdzie skaka³ nad ¶pi±cego pró¿niaczego br±zowego psa.
Ebcdic-US text: Ö¦@¢©¨‚’‰@ƒ©…™¦–•¨@“‰¢@‚…„©‰…@¢’’“@•„@¢—‰ƒ…‡–@—™–©•‰ƒ©…‡–@‚™©–¦…‡–@—¢K
Latin2 text again: Ow szybki czerwony lis bedzie skakal nad spiacego prozniaczego brazowego psa.

Done
