#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use FindBin;
use lib ("$FindBin::Bin/../lib");
use Acme::AjiFry;
use Acme::AjiFry::EN;

my $ajifry    = Acme::AjiFry->new();
my $ajifry_en = Acme::AjiFry::EN->new();

print $ajifry->translate_to_ajifry('おさしみ')."\n";
print $ajifry->translate_from_ajifry('食えアジフライお刺身食え食えお刺身ドボドボ岡星ドボドボ')."\n";

print $ajifry_en->translate_to_ajifry('012abcABC!!!')."\n";
print $ajifry_en->translate_from_ajifry('京極お刺身京極むむ･･･京極アジフライ食え食え食え食えドボドボ食えお刺身山岡ドボドボ山岡お刺身山岡むむ･･･!!!')."\n";
