#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Acme::MilkyHolmes;

my ($sherlock, $nero, $elly, $cordelia)  = Acme::MilkyHolmes->members();

$sherlock->say('ってなんでですかー');
$nero->say('僕のうまうま棒〜');
$elly->say('恥ずかしい...');
$cordelia->say('私の...お花畑...');

