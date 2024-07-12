use 5.010;
use strict;
use warnings;
use utf8;

use Data::Gimei;
use Test2::Bundle::More;

{    # to_s
    my $w = Data::Gimei::Word->new( [ '佐藤', 'さとう', 'サトウ', 'sato' ] );
    is $w->to_s, '佐藤, さとう, サトウ, Sato';
}

{    # like call by using positional args.

    # 4th args, romaji can be lower case
    my $w = Data::Gimei::Word->new( [ '鈴木', 'すずき', 'スズキ', 'suzuki' ] );

    is $w->kanji,    '鈴木';
    is $w->hiragana, 'すずき';
    is $w->katakana, 'スズキ';
    is $w->romaji,   'Suzuki';    # romaji capitalize initial char.
}

done_testing;
