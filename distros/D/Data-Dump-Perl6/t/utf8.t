#!perl -w

use utf8;
use strict;
use Test qw(plan ok);

plan tests => 2;

use Data::Dump::Perl6 qw(dump_perl6 quote_perl6);

local $Data::Dump::Perl6::UTF8 = 1;

my %hash = (
    șß => "Stanisław",
    Гđ => "Σωκράτης",
    台湾 => "民族",
    なまえ => "J\x{332}o\x{332}s\x{332}e\x{301}\x{332}",
);

ok(dump_perl6(\%hash)."\n", <<"EOT");
{ șß => "Stanisław", Гđ => "Σωκράτης", なまえ => "J\x{332}o\x{332}s\x{332}e\x{301}\x{332}", 台湾 => "民族" }
EOT

ok(quote_perl6("𝔘𝔫𝔦𝔠𝔬𝔡𝔢"), q{"𝔘𝔫𝔦𝔠𝔬𝔡𝔢"});
