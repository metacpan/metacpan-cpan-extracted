# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

binmode(STDOUT, ":utf8");  # but we still get wide char errors
binmode(STDERR, ":utf8");  # but we still get wide char errors
use Test::More qw(no_plan);
use utf8;
use strict;

use vars qw(
@toArabic
@toArabicIndic
@toBengali
@toBold
@toDevanagari
@toDoubleStruck
@toEthiopic
@toFullWidth
@toGujarati
@toGurmukhi
@toKannada
@toKhmer
@toLao
@toLimbu
@toMalayalam
@toMongolian
@toMonoSpace
@toMyanmar
@toOriya
@toOsmanya
@toRomanUpper
@toRomanLower
@toSansSerif
@toSansSerifBold
@toTamil
@toTelugu
@toThai
@toTibetan
);

@toArabic        = ( "٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩" );
@toArabicIndic   = ( "۰", "۱", "۲", "۳", "۴", "۵", "۶", "۷", "۸", "۹" );
@toBengali       = ( "০", "১", "২", "৩", "৪", "৫", "৬", "৭", "৮", "৯" );
@toBold          = ( "𝟎", "𝟏", "𝟐", "𝟑", "𝟒", "𝟓", "𝟔", "𝟕", "𝟖", "𝟗" );
@toDevanagari    = ( "०", "१", "२", "३", "४", "५", "६", "७", "८", "९" );
@toDoubleStruck  = ( "𝟘", "𝟙", "𝟚", "𝟛", "𝟜", "𝟝", "𝟞", "𝟟", "𝟠", "𝟡" );
@toEthiopic      = ( "0", "፩", "፪", "፫", "፬", "፭", "፮", "፯", "፰", "፱" );
@toFullWidth     = ( "０", "１", "２", "３", "４", "５", "６", "７", "８", "９" );
@toGujarati      = ( "૦", "૧", "૨", "૩", "૪", "૫", "૬", "૭", "૮", "૯" );
@toGurmukhi      = ( "੦", "੧", "੨", "੩", "੪", "੫", "੬", "੭", "੮", "੯" );
@toKannada       = ( "೦", "೧", "೨", "೩", "೪", "೫", "೬", "೭", "೮", "೯" );
@toKhmer         = ( "០", "១", "២", "៣", "៤", "៥", "៦", "៧", "៨", "៩" );
@toLao           = ( "໐", "໑", "໒", "໓", "໔", "໕", "໖", "໗", "໘", "໙" );
@toLimbu         = ( "᥆", "᥇", "᥈", "᥉", "᥊", "᥋", "᥌", "᥍", "᥎", "᥏" );
@toMalayalam     = ( "൦", "൧", "൨", "൩", "൪", "൫", "൬", "൭", "൮", "൯" );
@toMongolian     = ( "᠐", "᠑", "᠒", "᠓", "᠔", "᠕", "᠖", "᠗", "᠘", "᠙" );
@toMonoSpace     = ( "𝟶", "𝟷", "𝟸", "𝟹", "𝟺", "𝟻", "𝟼", "𝟽", "𝟾", "𝟿" );
@toMyanmar       = ( "၀", "၁", "၂", "၃", "၄", "၅", "၆", "၇", "၈", "၉" );
@toOriya         = ( "୦", "୧", "୨", "୩", "୪", "୫", "୬", "୭", "୮", "୯" );
@toOsmanya       = ( "𐒠", "𐒡", "𐒢", "𐒣", "𐒤", "𐒥", "𐒦", "𐒧", "𐒨", "𐒩" );
@toRomanUpper    = ( "0", "Ⅰ", "Ⅱ", "Ⅲ", "Ⅳ", "Ⅴ", "Ⅵ", "Ⅶ", "Ⅷ", "Ⅸ" );
@toRomanLower    = ( "0", "ⅰ", "ⅱ", "ⅲ", "ⅳ", "ⅴ", "ⅵ", "ⅶ", "ⅷ", "ⅸ" );
@toSansSerif     = ( "𝟢", "𝟣", "𝟤", "𝟥", "𝟦", "𝟧", "𝟨", "𝟩", "𝟪", "𝟫" );
@toSansSerifBold = ( "𝟬", "𝟭", "𝟮", "𝟯", "𝟰", "𝟱", "𝟲", "𝟳", "𝟴", "𝟵" );
@toTamil         = ( "0", "௧", "௨", "௩", "௪", "௫", "௬", "௭", "௮", "௯" );
@toTelugu        = ( "౦", "౧", "౨", "౩", "౪", "౫", "౬", "౭", "౮", "౯" );
@toThai          = ( "๐", "๑", "๒", "๓", "๔", "๕", "๖", "๗", "๘", "๙" );
@toTibetan       = ( "༠", "༡", "༢", "༣", "༤", "༥", "༦", "༧", "༨", "༩" );

require Convert::Number::Digits;

is ( 1, 1, "loaded." );

my $count = 0;

my $d = new Convert::Number::Digits;

my @methods = $d->toMethods;

no strict 'refs';

foreach my $digit (0..9) {
	foreach my $system ( @methods ) {	
		next if ( $system eq "toWestern" );
		$count++;
		my $xdigit = $d->$system ( $digit );
		is ( ($xdigit eq ${"${system}"}[$digit]), 1, "$system: $digit => $xdigit" );
		$count++;
		my $reDigit = $d->convert ( $xdigit );
		is ( ($digit == $reDigit), 1, "$system: $xdigit => $digit" );
	}
}

