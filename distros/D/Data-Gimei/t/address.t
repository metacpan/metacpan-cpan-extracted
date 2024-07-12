use 5.010;
use strict;
use warnings;
use utf8;

use Data::Gimei;
Data::Gimei::Address::load('t/addresses.yml');

use Test2::Bundle::More;

{    # to_s
    my $addr = Data::Gimei::Address->new();

    is $addr->to_s,
        '北海道 札幌市中央区 モエレ沼公園, '
      . 'ほっかいどう さっぽろしちゅうおうく もえれぬまこうえん, '
      . 'ホッカイドウ サッポロシチュウオウク モエレヌマコウエン';
}

{
    my $addr = Data::Gimei::Address->new();

    is $addr->kanji,          '北海道札幌市中央区モエレ沼公園';
    is $addr->hiragana,       'ほっかいどうさっぽろしちゅうおうくもえれぬまこうえん';
    is $addr->katakana,       'ホッカイドウサッポロシチュウオウクモエレヌマコウエン';
    ok !$addr->can('romaji'), "Address doesn't define method romaji().";

    is $addr->prefecture->kanji,    '北海道';
    is $addr->prefecture->hiragana, 'ほっかいどう';
    is $addr->prefecture->katakana, 'ホッカイドウ';
    is $addr->prefecture->romaji,   undef;

    is $addr->city->kanji,    '札幌市中央区';
    is $addr->city->hiragana, 'さっぽろしちゅうおうく';
    is $addr->city->katakana, 'サッポロシチュウオウク';
    is $addr->city->romaji,   undef;

    is $addr->town->kanji,    'モエレ沼公園';
    is $addr->town->hiragana, 'もえれぬまこうえん',;
    is $addr->town->katakana, 'モエレヌマコウエン';
    is $addr->town->romaji,   undef;
}

done_testing;
