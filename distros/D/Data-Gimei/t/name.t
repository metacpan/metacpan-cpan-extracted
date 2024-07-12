use 5.010;
use strict;
use warnings;
use utf8;

use Data::Gimei;
Data::Gimei::Name::load('t/names.yml');

use Test2::Bundle::More;

{    # test Name#to_s
    my $name = Data::Gimei::Name->new( gender => 'male' );
    is $name->to_s, 'male, 佐藤 愛斗, さとう あいと, サトウ アイト, Aito Sato';
}

{    # test constructor of Name
    my $name = Data::Gimei::Name->new( gender => 'male' );

    is $name->gender,         'male';
    is $name->kanji,          '佐藤 愛斗';
    is $name->hiragana,       'さとう あいと';
    is $name->katakana,       'サトウ アイト';
    is $name->romaji,         'Aito Sato';
    is $name->forename->to_s, '愛斗, あいと, アイト, Aito';
    is $name->surname->to_s,  '佐藤, さとう, サトウ, Sato';
}

{    # test separater of kanji/katakana/hiragana/romaji
    my $name = Data::Gimei::Name->new( gender => 'male' );
    is $name->kanji('/'),    '佐藤/愛斗';
    is $name->hiragana('/'), 'さとう/あいと';
    is $name->katakana('/'), 'サトウ/アイト';
    is $name->romaji('/'),   'Aito/Sato';
}

{    # test Name#gender
    my $name = Data::Gimei::Name->new( gender => 'female' );
    is $name->gender, 'female';
}

done_testing;
