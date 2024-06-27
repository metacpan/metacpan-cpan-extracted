use strict;
use warnings;
use utf8;
use Test::More;
use Test::Base;
use Aozora2Epub::XHTML;
use lib qw/./;
use t::Util;

plan tests => 1 * blocks;

sub eval_unicode_notation {
    my $s = shift;
    $s =~ s|\\x\{([0-9a-fA-F]+)\}|chr(hex($1))|esg;
    return $s;
}

filters {
    input => 'chomp',
    expected => ['chomp', 'eval_unicode_notation'],
};

run {
    my $block = shift;

    my $got = Aozora2Epub::XHTML::conv_gaiji_title_author($block->input);
    is $got, $block->expected, $block->name;
};

__DATA__

=== normal jis
--- input
大倉※［＃「火＋華」、第3水準1-87-62］子
--- expected
大倉\x{71c1}子

=== normal jis top
--- input
※［＃「さんずい＋（壥－土へん－厂）」、第3水準1-87-25］上漁史
--- expected
\x{6ff9}上漁史

=== unchanged
--- input
勇士ウ※［＃小書き片仮名ヲ］ルター
--- expected
勇士ウ※［＃小書き片仮名ヲ］ルター

=== normal jis double
--- input
歌　※［＃ローマ数字1、1-13-21］・※［＃ローマ数字2、1-13-22］
--- expected
歌　\x{2160}・\x{2161}

=== not kome
--- input
（２［＃「２」はローマ数字、1-13-22］）
--- expected
（\x{2161}）

=== unicode
--- input
たま※［＃「ころもへん＋攀」、U+897B］
--- expected
たま\x{897b}

=== unicode bad font
--- input
失※［＃「人がしら／二／心」、U+2B779、表紙］術講義
--- expected
失※［＃「人がしら／二／心」、U+2B779、表紙］術講義
--- note
2b779はkindleだと豆腐になる

=== no chuuki
--- input
あいうえお
--- expected
あいうえお
