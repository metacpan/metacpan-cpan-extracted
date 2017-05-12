
use strict;
use Test::More tests => 19;

use Business::Barcode::EAN13 qw/:all/;

ok valid_barcode("5023965006028"),  "valid barcode"; 
ok !valid_barcode("5023965006027"), "invalid barcode";
is check_digit("502396500602"), 8,  "checkdigit";
is check_digit("503069708024"), 0,  "zero checkdigit";

# Returns undef with invalid checkdigit
{
  # We don't actually want to print the warning
  local $SIG{__WARN__} = sub {};
  is check_digit("50239650060"), undef, "invalid stem for check digit";
}

# Picks correct barcode from a list
{
  my @barcodes = qw/5391500385083 5014138036041/;
  is best_barcode(\@barcodes, [50, 539]), "5014138036041", "best barcode UK vs IE";
}

# Picks correct barcode from a list
{
  my @barcodes = qw/5391500385083 5014138036041/;
  is best_barcode(\@barcodes, [539, 50]), "5391500385083", "best barcode IE vs UK";
}

# Picks correct barcode from a list
{
  my @barcodes = qw/5391500385083 5014138036041/;
  is best_barcode(\@barcodes, ["uk", "ie"]), "5014138036041", "best barcode UK vs IE named";
}

# Picks correct barcode from a list
{
  my @barcodes = qw/5391500385083 5014138036041/;
  is best_barcode(\@barcodes, ["ie", "uk"]), "5391500385083", "best barcode IE vs UK named";
}

# Fails to pick a best barcode cos none are valid (no prefs)
{
  my @barcodes = qw/5023965006027 602396500602 50239650060289/;
  is undef, best_barcode(\@barcodes), "no best barcode, no prefs";
}

# Fails to pick a best barcode cos none are valid (UK prefs)
{
  my @barcodes = qw/5023965006027 602396500602 50239650060289/;
  my @prefs = qw/50/;
  is undef, best_barcode(\@barcodes, \@prefs), "no best barcode, prefs";
}

# Fails to pick a best barcode cos none are valid (named prefs)
{
  my @barcodes = qw/5023965006027 602396500602 50239650060289/;
  my @prefs = qw/uk ie/;
  is undef, best_barcode(\@barcodes, \@prefs), "no best barcode, named prefs";
}

# Picks correct barcode from a list, with no preferences
# and only one valid barcode
{
  my @barcodes = qw/5023965006028 5023965006027 502396500602 50239650060289/;
  is best_barcode(\@barcodes), "5023965006028", "best barcode, no prefs";
}

# Picks correct barcode from a list, with UK preference, but
# only one valid barcode
{
  my @prefs = qw/50/;
  my @barcodes = qw/5023965006028 5023965006027 502396500602 50239650060289/;
  is best_barcode(\@barcodes, \@prefs), "5023965006028", "best barcode, top pref";
}

# Picks correct barcode from a list, with non-existing preference, but
# only one valid barcode
{
  my @prefs = qw/70/;
  my @barcodes = qw/5023965006026 5023965006028 5023965006027 502396500602 50239650060289/;
  is best_barcode(\@barcodes, \@prefs), "5023965006028", "best barcode, none in prefs";
}

# Add some tests for fall through to invalids ...

# Test issuing country
is issuer_ccode("5023965006028"), "uk", "issuing country: uk";
is issuer_ccode("4303391576359"), "de", "issuing country: de";
is issuer_ccode("4601620100277"), "ru", "issuing country: ru";
is issuer_ccode("9999999999999"), "", "issuing country: n/a";

