# Convert-Number-Roman
Conversion Between the Indo-Arabic and Roman Numeral Systems with Perl

# Overview
Why Another Roman Numeral Conversion Package?

This package offers Roman numeral conversions in Unicode encoding
which other packages do not offer at the time of this writing.
Additionally, the `Convert::Number::Roman` package applies the algorithm
in the CSS3-List module recommendation which works for a wide range
of integers:

  [http://www.w3.org/TR/css3-lists](/http://www.w3.org/TR/css3-lists/)

The interface of the `Convert::Number::Roman` package is identical to
other `Convert::Number::` packages such as `::Ethiopic` and `::Coptic`.

Presently the package works best with Perl 5.8.0, it has not been
satisfactorily tested on older versions.
