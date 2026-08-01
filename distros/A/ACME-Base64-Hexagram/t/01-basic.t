#!/usr/bin/perl
use warnings;
use strict;
use utf8;

use ACME::Base64::Hexagram qw{ encode_base64h decode_base64h };

use Test::More tests => 2;


my $string = "Just Another Perl Hacker,\n";

my $result = "䷒䷧䷕䷳䷝䷂䷁䷁䷛䷦䷽䷴䷚䷆䷕䷲䷈䷅䷁䷥䷜䷦䷰䷠䷒䷆䷅䷣䷚䷶䷕䷲䷋䷀䷨·";

is encode_base64h($string), $result . "\n", 'encoding';
is decode_base64h($result), $string, 'decoding';
