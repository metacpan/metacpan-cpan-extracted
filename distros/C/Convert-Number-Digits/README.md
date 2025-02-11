# Convert-Number-Digits
Convert Digits Between the Scripts of Unicode


# SYNOPSIS
```
  use utf8;
  require Convert::Number::Digits;

  my $number = 12345;
  my $d = new Convert::Number::Digits ( $number );
  print "$number => ", $d->toArabic, "\n";

  my $gujarti = $d->toGujarti;
  my $khmer = reverse ( $d->toKhmer );
  $d->number ( $khmer );  # reset the number
  print "$number => $gujarti => ", $d->number, " => ", $n->convert, "\n";
```

#  DESCRIPTION

The `Convert::Number::Digits` module will convert a sequence of digits from one
script supported in Unicode, into another.  UTF-8 encoding is used
for all scripts.


## METHODS


* `convert` - outputs digits in Western script (0-9).

* `toMethods` - get a list of the following conversion methods:

  * `toArabic` - output digits in Arabic script (١-٢).
  * `toArabicIndic` - output digits in ArabicIndic script (۱-۲).
  * `toBengali` - output digits in Bengali script (১-২).
  * `toBold` - output digits in Bold script (𝟏-𝟐).
  * `toDevanagari` - output digits in Devanagari script (१-२).
  * `toDoubleStruck` - output digits in DoubleStruck script (𝟙-𝟚).
  * `toEthiopic` - output digits in Ethiopic script (፩-፪).
  * `toFullWidth` - output digits in FullWidth script (１-２).
  * `toGujarati` - output digits in Gujarati script (૧-૨).
  * `toGurmukhi` - output digits in Gurmukhi script (੧-੨).
  * `toKannada` - output digits in Kannada script (೧-೨).
  * `toKhmer` - output digits in Khmer script (១-២).
  * `toLao` - output digits in Lao script (໑-໒).
  * `toLimbu` - output digits in Limbu script (᥆-᥏).
  * `toMalayalam` - output digits in Malayalam script (൧-൨).
  * `toMongolian` - output digits in Mongolian script (᠑-᠒).
  * `toMonoSpace` - output digits in MonoSpace script (𝟷-𝟸).
  * `toMyanmar` - output digits in Myanmar script (၁-၂).
  * `toOriya` - output digits in Oriya script (୧-୨).
  * `toOsmanya` - output digits in Osmanya script (𐒠-𐒩).
  * `toRomanLower` - output digits in lowercase Roman numerals (ⅰ-ⅸ).
  * `toRomanUpper` - output digits in uppercase Roman numerals (Ⅰ-Ⅸ).
  * `toSansSerif` - output digits in SansSerif script (𝟣-𝟤).
  * `toSansSerifBold` - output digits in SansSerifBold script (𝟭-𝟮).
  * `toTamil` - output digits in Tamil script (௧-௨).
  * `toTelugu` - output digits in Telugu script (౧-౨).
  * `toThai` - output digits in Thai script (๑-๒).
  * `toTibetan` - output digits in Tibetan script (༡-༢).


# CAVAETS

Ethiopic, Roman and Tamil scripts do not have a zero.  Western 0 is used instead.

Though a script has digits its numeral system is not necessarily digital.
For example, Roman, Coptic, Ethiopic, Greek and Hebrew.  If you convert
digits into these systems it is assumed that you know what you are doing
(and your starting number is an applicable sequence).  The `Convert::Number::Digits`
package converts digits and not numbers.


# REQUIRES

The package is known to work on Perl 5.6.1 and 5.8.0 but has not been tested on
other versions of Perl by the author. 
