#!perl -T

use lib 't';
use Test::More tests => 46;
use strict;
use utf8;
use warnings;
$^W=0;

eval 'use Convert::Number::Greek  "greek2num"';
ok($@ eq '');
sub greek2num($;$);

sub t($$) { is greek2num(shift), shift }

our $warnings;
$SIG{__WARN__} = sub {
	++ $warnings;
	#diag(shift);
};
t '  α   ', 1;
cmp_ok $warnings, '==', 0;
t ' β-', 2;
cmp_ok $warnings, '==', 1;
t 'γδεϛ', 18;
t 'αλφα', 532;
t 'ιζ', 17;
t 'κη', 28;
t 'θλ', 39;
t 'ρμ', 140;
t 'ρνε', 155;
t 'σξ', 260;
t 'το', 370;
t 'υπ', 480;
t 'φϟα', 591;
t 'χΑ', 601;
t 'ψΒ', 702;
t 'ωΓ', 803;
t 'ϡΔ', 904;
t 'ΙΕ', 15;
t 'ΚϚ', 26;
t 'ΛΖ', 37;
t 'ΜΗ', 48;
t 'ΝΘ', 59;
t 'ΡΞ', 160;
t 'ΣΟ', 270;
t 'ΤΠ', 380;
t 'ΥϞ', 490;
t 'Φϙ', 590;
t 'ΧϘ', 690;
t 'ᾳΨ', 1700;
t 'ῃΩ', 8800;
t 'ῳϠ', 800900;
t ',ᾼ', 1000000;
t '͵ῌ', 8000000;
t ',͵ῼ', 800000000000;
t "͵͵ι͵͵β͵τ͵μ͵εχοη'", 12345678;
t ',,ϟ,,η,ψ,ξ,ευλβ’', 98765432;
t ' ϠΙΣΤ´', 916;
t 'ϡνστ΄', 956;
t '͵σ͵πψπθʹ ', 280789;
cmp_ok $warnings, '==', 1;
t '͵βζ ʹ', 2007;
cmp_ok $warnings, '==', 2;
no warnings 'numeric';
greek2num '͵βζ ʹ';
cmp_ok $warnings, '==', 2;
