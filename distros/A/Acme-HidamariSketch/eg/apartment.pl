#!perl
use strict;
use warnings;
use utf8;
use File::Spec;
use File::Basename;
use lib File::Spec->catdir(dirname(__FILE__), '../lib');
binmode(STDOUT, ":utf8");

use Acme::HidamariSketch;

my $hidamari = Acme::HidamariSketch->new;
my $apartment = $hidamari->apartment;

# ドアをノックしないとだめっしょ？
# $apartment->knock;

# 各部屋をノックすると会えます
printf "\n[ 3年目 ]\n";
printf $apartment->knock(201)->{name_ja} . "\n";
printf $apartment->knock(202)->{name_ja} . "\n";
printf $apartment->knock(203)->{name_ja} . "\n";
printf $apartment->knock(101)->{name_ja} . "\n";
printf $apartment->knock(103)->{name_ja} . "\n";

# 存在しない部屋はノックできないよ？
# $apartment->knock(104);

# 沙英さんとヒロさんがいない？
# なら時間を戻しましょう
$hidamari->year('second');
$apartment = $hidamari->apartment;

# これで沙英さんとヒロさんにも会えます
printf "\n[ 2年目 ]\n";
printf $apartment->knock(201)->{name_ja} . "\n";
printf $apartment->knock(202)->{name_ja} . "\n";
printf $apartment->knock(203)->{name_ja} . "\n";
printf $apartment->knock(101)->{name_ja} . "\n";
printf $apartment->knock(102)->{name_ja} . "\n";
printf $apartment->knock(103)->{name_ja} . "\n";

# 全ての年度を網羅してます
$hidamari->year('first');
$apartment = $hidamari->apartment;

printf "\n[ 1年目 ]\n";
printf $apartment->knock(201)->{name_ja} . "\n";
printf $apartment->knock(202)->{name_ja} . "\n";
printf $apartment->knock(101)->{name_ja} . "\n";
printf $apartment->knock(102)->{name_ja} . "\n";

# もちろんリリさんとみさとさんも帰ってきます
$hidamari->year('before');
$apartment = $hidamari->apartment;

printf "\n[ 前年 ]\n";
printf $apartment->knock(201)->{name_ja} . "\n";
printf $apartment->knock(203)->{name_ja} . "\n";
printf $apartment->knock(101)->{name_ja} . "\n";
printf $apartment->knock(102)->{name_ja} . "\n";

