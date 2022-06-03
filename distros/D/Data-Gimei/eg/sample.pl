#!/usr/bin/env perl

use warnings;
use v5.22;
binmode STDOUT, ":utf8";

use Data::Gimei;
my $name = Data::Gimei::Name->new();
                                    # for example
say $name->kanji;                   # "斎藤 陽菜"
say $name->hiragana;                # "さいとう はるな"
say $name->katakana;                # "サイトウ ハルナ"
say $name->romaji;                  # "Haruna Saito"

say $name->family->kanji;           # "斎藤"
say $name->family->hiragana;        # "さいとう"
say $name->family->katakana;        # "サイトウ"
say $name->family->romaji;          # "Saito"

say $name->given->kanji;            # "陽菜"
say $name->given->hiragana;         # "はるな"
say $name->given->katakana;         # "ハルナ"
say $name->given->romaji;           # "Haruna"

say $name->gender;                  # "female"

my $addr = Data::Gimei::Address->new();
say $addr->kanji;                   # "北海道札幌市中央区モエレ沼公園"
say $addr->hiragana;                # "ほっかいどうさっぽろしちゅうおうくもえれぬまこうえん"
say $addr->katakana;                # "ホッカイドウサッポロシチュウオウクモエレヌマコウエン"

say $addr->prefecture->kanji;       # "北海道"
say $addr->prefecture->hiragana;    # "ほっかいどう"
say $addr->prefecture->katakana;    # "ホッカイドウ"

say $addr->city->kanji;             # "札幌市中央区"
say $addr->city->hiragana;          # "さっぽろしちゅうおうく"
say $addr->city->katakana;          # "サッポロシチュウオウク"

say $addr->town->kanji;             # "モエレ沼公園"
say $addr->town->hiragana;          # "もえれぬまこうえん"
say $addr->town->katakana;          # "モエレヌマコウエン"
