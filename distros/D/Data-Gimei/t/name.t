use warnings;
use v5.22;
use utf8;

use Test::More;

use Data::Gimei;
Data::Gimei::Name::load('t/names.yml');

{
    my $gimei = Data::Gimei::Name->new( gender => 'male' );
    is $gimei->kanji,    '佐藤 愛斗';
    is $gimei->hiragana, 'さとう あいと';
    is $gimei->katakana, 'サトウ アイト';
    is $gimei->romaji,   'Aito Sato';
    is $gimei->gender,   'male';

    is $gimei->given->kanji,    '愛斗';
    is $gimei->given->hiragana, 'あいと';
    is $gimei->given->katakana, 'アイト';
    is $gimei->given->romaji,   'Aito';

    is $gimei->family->kanji,    '佐藤';
    is $gimei->family->hiragana, 'さとう';
    is $gimei->family->katakana, 'サトウ';
    is $gimei->family->romaji,   'Sato';
}

{
    my $gimei = Data::Gimei::Name->new( gender => 'female' );
    is $gimei->gender, 'female';
}

done_testing;
