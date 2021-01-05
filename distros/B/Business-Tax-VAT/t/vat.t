#!/usr/bin/perl -w

use Test::More;

use strict;
BEGIN {
    require Business::Tax::VAT;
}

my $vat = Business::Tax::VAT->new(qw/uk ie/);

{
  my $vat = Business::Tax::VAT->new(qw/gb/);

  $Business::Tax::VAT::Price::RATE{'gb'} = 20;

  my $price = $vat->item(102 => 'gb');
  is $price->full, 102, "Full price correct - GB consumer";
  is $price->vat,  17,  "VAT correct - GB consumer";
  is $price->net,  85,   "Net price correct - GB consumer";
}

{
  my $price = $vat->item(102 => 'uk');
  is $price->full, 102, "Full price correct - UK consumer";
  is $price->vat,  0,  "VAT correct - UK consumer";
  is $price->net,  102,   "Net price correct - UK consumer";
}

{
  my $price = $vat->item(102);
  is $price->full, 102, "Full price correct - implied UK consumer";
  is $price->vat,  0, "VAT correct - implied UK consumer";
  is $price->net,  102,   "Net price correct - implied UK consumer";
}

{
  my $price = $vat->item(123 => 'ie');
  is $price->full, 123, "Full price correct - ie consumer";
  is $price->vat,   23, "VAT correct - ie consumer";
  is $price->net,  100, "Net price correct - ie consumer";
}

{
  my $price = $vat->item(123 => 'IE');
  is $price->full, 123, "Full price correct - IE consumer";
  is $price->vat,   23, "VAT correct - IE consumer";
  is $price->net,  100, "Net price correct - IE consumer";
}

{
  my $price = $vat->business_item(100 => 'IE');
  is $price->full, 123, "Full price correct - IE business";
  is $price->vat,   23, "VAT correct - IE business";
  is $price->net,  100, "Net price correct - IE business";
}

{
  my $price = $vat->item(100 => 'de');
  is $price->full, 100, "Full price correct - de consumer";
  is $price->vat,    0, "No VAT - de consumer";
  is $price->net,  100, "Net price correct - de consumer";
}

{
  local $Business::Tax::VAT::Price::RATE{at} = 0;
  my $price = $vat->item(100 => 'at');
  is $price->full, 100, "Full price correct - AT transport";
  is $price->vat,    0, "No VAT - AT transport";
  is $price->net,  100, "Net price correct - AT transport";
}

done_testing();
