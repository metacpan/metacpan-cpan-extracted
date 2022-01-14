use strict;
use warnings;

use English;
use utf8;
use feature ':5.30';

use Test::More;

use Data::Gimei;
Data::Gimei::Address::load('t/addresses.yml');

my $addr = Data::Gimei::Address->new();
is $addr->kanji,    '北海道札幌市中央区モエレ沼公園';
is $addr->hiragana, 'ほっかいどうさっぽろしちゅうおうくもえれぬまこうえん';
is $addr->katakana, 'ホッカイドウサッポロシチュウオウクモエレヌマコウエン';

is $addr->prefecture->kanji,    '北海道';
is $addr->prefecture->hiragana, 'ほっかいどう';
is $addr->prefecture->katakana, 'ホッカイドウ';

is $addr->city->kanji,    '札幌市中央区';
is $addr->city->hiragana, 'さっぽろしちゅうおうく';
is $addr->city->katakana, 'サッポロシチュウオウク';

is $addr->town->kanji,    'モエレ沼公園';
is $addr->town->hiragana, 'もえれぬまこうえん',;
is $addr->town->katakana, 'モエレヌマコウエン';

done_testing;
