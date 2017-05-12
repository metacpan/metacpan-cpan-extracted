use strict;
use warnings;
use utf8;
use Test::More;

use Acme::EnclosedChar qw/
    enclose
    enclose_katakana
    enclose_week_ja
    enclose_kansuji
    enclose_kanji
    enclose_all
/;

is enclose(), '';
is enclose(undef), '';

is enclose('0'), '⓪';
is enclose('1'), '①';
is enclose('12'), '⑫';
is enclose('012345'), '⓪①②③④⑤';
is enclose('0!12!34!5!'), '⓪!⑫!㉞!⑤!';
is enclose('Perl'), 'Ⓟⓔⓡⓛ';
is enclose('A45A'), 'Ⓐ㊺Ⓐ';
is enclose('45A'), '㊺Ⓐ';
is enclose('A45'), 'Ⓐ㊺';
is enclose('Rubyは1993/2/24生まれ'), 'Ⓡⓤⓑⓨは①⑨⑨③/②/㉔生まれ';
is enclose('1-2+3*4=11'), '①⊖②⊕③⊛④⊜⑪';

is enclose_katakana('アロハ'), '㋐㋺㋩';

is enclose_week_ja('月曜から金曜まで'), '㊊曜から㊎曜まで';

is enclose_kansuji('加藤一二三'), '加藤㊀㊁㊂';

is enclose_kanji('夜は会社休み'), '㊰は会㊓㊡み';

is enclose_all('8月25日の水曜の夜中だよ！Bye!'), '⑧㊊㉕㊐の㊌曜の㊰㊥だよ！Ⓑⓨⓔ!';


done_testing;
