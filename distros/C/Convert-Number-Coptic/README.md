# Convert-Number-Coptic
Conversion between the Indo-Arabic and Coptic numeral systems with Perl.

## Why Convert::Number::Coptic?

  Because it wasn't there :)  The goal for this package is to provide
  numeral and date conversion services in pure Perl under Coptic
  conventions.

## What This Package Can Do

  At this point numeral system conversion between Western (Arabic, base 10)
  and Coptic.  Coptic numerals sequences must be in UTF-8.  The package is
  known to work on Perl 5.6.1 and has not been tested on other versions of
  Perl by the author. 

  Coptic numerals can be formatted in two ways.  The standard convention
  is to use only underlines from 10^3 and onward.  A lesser used convention
  accumulates only overlines.  This package uses the standard convention.

  Unicode does not define which diacritical symbols should be used for
  composing Coptic numerals.  The solution here is to use U+0304 for single
  overline, U+0331 for single underline and U+0347 for double underline.

  Since Unicode lacks diacritical symbols to build up numbers indefinitely
  (can't blame Unicode here) a complication arises for numbers of 1 billion
  or larger.  Since there is no triple or quadruple, etc, underline non-spacing
  diacritical marks, this package simply appends extra diacritical symbols.
  For example:
  

    10^5 => (U+03C1)(U+0331)
    10^6 => (U+03B1)(U+0347)
    10^7 => (U+03B9)(U+0347)
    10^8 => (U+03C1)(U+0347)
    10^9 => (U+03B1)(U+0347)(U+0331)
    10^10 => (U+03B9)(U+0347)(U+0331)
    10^11 => (U+03C1)(U+0347)(U+0331)
    10^12 => (U+03B1)(U+0347)(U+0347)
      ⋮   ⋮     ⋮        ⋮       ⋮


  The shared Greek-Coptic range of Unicode is used by this package.  This
  will be update when Unicode is revised to better support Coptic.
