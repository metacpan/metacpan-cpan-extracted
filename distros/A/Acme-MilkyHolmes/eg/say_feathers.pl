#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Acme::MilkyHolmes qw($MilkyHolmesFeathers);

my ($kazumi, $alice)  = Acme::MilkyHolmes->members_of($MilkyHolmesFeathers);
$kazumi->color_enable(1);
$alice->color_enable(1);
$kazumi->say('アローのトイズ！');
$alice->say('バウンドのトイズ！');

