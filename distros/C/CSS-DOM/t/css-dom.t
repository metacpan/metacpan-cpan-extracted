#!/usr/bin/perl -T

use strict; use warnings;
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
use Test::More;
plan tests => $tests;

use tests 2;
require CSS::DOM;
my $u = \'u';
my $p = \'p';
my $sheet = new CSS::DOM url_fetcher => $u, property_parser => $p;
is $sheet->url_fetcher, $u, 'url_fetcher';
is $sheet->property_parser, $p, 'property_parser';

use tests 1; # compute_style
{
 # compute_style actually expects an HTML::DOM::Element, but HTML::DOM
 # depends on CSS::DOM, so we cannot easily test it without a recursive
 # dependency.  So we use a dummy class.
 package MyElem;
 AUTOLOAD { $_[0]{(our $AUTOLOAD =~ /.*::(.*)/)[0]} }
}
{
 my $w;
 local $SIG{__WARN__} = sub { $w .= shift };
 require CSS::DOM::Style;
 my $elem = bless{
  style => CSS'DOM'Style'parse('color:red'), tagName => 'p',
 }, MyElem=>;
 CSS::DOM::compute_style(element => $elem);
 is $w, undef, 'no warnings for style belonging to element itself';
 # This warning used to occur (before 0.15) if no applicable property with
 # the same name was to be found in the style sheets.
}
