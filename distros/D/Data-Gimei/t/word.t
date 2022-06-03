use warnings;
use v5.22;
use utf8;

use Test::More;

use Data::Gimei;

#
# call by using named args.
#

my $word = Data::Gimei::Word->new(
    kanji    => '田中',
    hiragana => 'たなか',
    katakana => 'タナカ',
    romaji   => 'tanaka'    # args romaji can be lower case
);
is $word->kanji,    '田中';
is $word->hiragana, 'たなか';
is $word->katakana, 'タナカ';
is $word->romaji,   'Tanaka';    # romaji capitalizes initial char.

#
# like call by using positional args.
#

# 4th args, romaji can be lower case
$word = Data::Gimei::Word->new( [ '鈴木', 'すずき', 'スズキ', 'suzuki' ] );

is $word->kanji,    '鈴木';
is $word->hiragana, 'すずき';
is $word->katakana, 'スズキ';
is $word->romaji,   'Suzuki';    # romaji capitalize initial char.

done_testing;
