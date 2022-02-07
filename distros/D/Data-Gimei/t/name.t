use strict;
use warnings;
use feature ':5.12';
use utf8;

use Test::More tests => 5;

use Data::Gimei;
Data::Gimei::Name::load('t/names.yml');

my $gimei = Data::Gimei::Name->new( gender => 'male' );
is $gimei->kanji,    '佐藤 愛斗';
is $gimei->hiragana, 'さとう あいと';
is $gimei->katakana, 'サトウ アイト';
is $gimei->romaji,   'Aito Sato';
is $gimei->gender,   'male';
