use strict;
use utf8;
use Test::Base;
use Encode;

use Acme::Samurai;

plan tests => 1 * blocks;

# use YAML;
# Acme::Samurai->add_trigger('pre.node_filter' => sub { warn Dump $_[1]->feature });

run {
    my $block = shift;
    is(
        Acme::Samurai->gozaru($block->input) => $block->expected,
        encode_utf8($block->input . ' / ' . $block->name)
    );
};

__DATA__
=== 一般名詞, 固有名詞
--- input:    今日も東京は快晴。
--- expected: 今日もお江戸は日本晴れ。
=== 代名詞, 形容詞
--- input:    わたしが何か悪いことを。
--- expected: それがしが何か良からぬことを。
=== 接続詞, 連体詞
--- input:    だけど、なんで？ 本当か、そんなはずは！
--- expected: けれど、何ゆえ？ まことか、左様なはずは！
=== 副詞
--- input:    なぜパパとコギャルが警察に？
--- expected: 何ゆえ父上と小娘が奉行所に？
=== 接尾語
--- input:    田中さん、オレそんなつもりは。
--- expected: 田中どの、拙者左様な所存は。
=== 動詞 下さい
--- input:    すみませんが、100円下さい。
--- expected: 申し訳ないが、百両くだされ。
=== 動詞 できる
--- input:    できればお願いします。
--- expected: できますればお願いしまする。
=== 名詞 非自立
--- input:    そんなつもりはありません。
--- expected: 左様な所存はありませぬ。
=== 動詞 いる
--- input:    準備しているところだが
--- expected: 仕度しておるところでござるが

=== 名詞
--- input:    お元気で。
--- expected: お達者で。
=== 名詞 例外
--- input:    元気な子供
--- expected: 元気な子供

=== 数
--- input:    36.5度 ４２．１９５キロ 千グラム
--- expected: 三十六.五度 四十二．一九五里 千匁
=== 数ゼロ始まり
--- input:    0120
--- expected: 零一二零

=== 大字
--- input:    三十四回 一万円
--- expected: 参拾四回 壱萬両

=== ござる です基本形
--- input:    侍です。
--- expected: 侍でござる。
=== ござる です基本形 （+ 助詞）
--- input:    侍ですけど、
--- expected: 侍でござるが、
=== ござる です未然形
--- input:    侍でしょう。
--- expected: 侍でござろう。
=== ござる です未然形
--- input:    侍でしょうが、
--- expected: 侍でござろうが、
=== ござる です連用形
--- input:    侍でした。
--- expected: 侍でござった。
=== ござる です連用形
--- input:    侍でしたが、
--- expected: 侍でござったが、

=== ござる だ基本形
--- input:    侍だ。
--- expected: 侍でござる。
=== ござる だ基本形
--- input:    侍だけど、
--- expected: 侍でござるが、
=== ござる だ未然系
--- input:    侍だろう。
--- expected: 侍でござろう。
=== ござる だ連用タ接続
--- input:    侍だった。
--- expected: 侍でござった。
=== ござる だ連用タ接続
--- input:    侍だったが、
--- expected: 侍でござったが、

=== 助詞, 助動詞
--- input:    そうじゃない？
--- expected: そうではない？
=== 助動詞
--- input:    そうかも。
--- expected: そうやも。
=== 助動詞
--- input:    準備したなら、
--- expected: 仕度したなれば、
=== 助動詞
--- input:    そうします。
--- expected: そうしまする。
=== 終助詞
--- input:    そうしなさい。
--- expected: そうしなされ。
=== 終助詞
--- input:    そうだな。
--- expected: そうでござるのう。
=== 終助詞
--- input:    そうですね。
--- expected: そうでござるな。

=== ござる ある基本形
--- input:    侍である。
--- expected: 侍でござる。
=== ござる ある仮定形
--- input:    侍であれば
--- expected: 侍でござれば
=== ござる ある命令ｅ
--- input:    侍であれ！
--- expected: 侍でござれ！
=== ござる ある連用タ接続
--- input:    侍であった。
--- expected: 侍でござった。

=== ぬ 不定形基本形
--- input:    走ってはいけません。
--- expected: 走ってはいけませぬ。
=== ぬ 不定形基本形
--- input:    行けませんが、メールします。
--- expected: 参れませぬが、文しまする。

=== 参る 仮定形
--- input:    行けば、
--- expected: 参れば、
=== 参る 基本形
--- input:    行く。
--- expected: 参る。
=== 参る 未然ウ接続
--- input:    行こうと、
--- expected: 参ろうと、
=== 参る 未然形
--- input:    行かない。
--- expected: 参らぬ。
=== 参る 連用タ接続
--- input:    行った。
--- expected: 参った。
=== 参る 連用形
--- input:    行きかた。
--- expected: 参りかた。

=== 申す 仮定形
--- input:    言えば、
--- expected: 申せば、
=== 申す 基本形
--- input:    言う。
--- expected: 申す。
=== 申す 未然ウ接続
--- input:    言おうと、
--- expected: 申そうと、
=== 申す 未然形
--- input:    言わない。
--- expected: 申さぬ。
=== 申す 連用タ接続
--- input:    言った。
--- expected: 申した。
=== 申す 連用形
--- input:    言いかた。
--- expected: 申しかた。

=== 心得る 知る 基本形
--- input:    知る。
--- expected: 心得る。
=== 心得る 知る 未然形
--- input:    知れたら
--- expected: 心得たら
=== 心得る 知る 連用タ接続
--- input:    知ったよ
--- expected: 心得たなり
=== 心得る 知る 連用形
--- input:    知りたい
--- expected: 心得たい

=== 心得る わかる 基本形
--- input:    わかる。
--- expected: 心得る。
=== 心得る わかる 未然形
--- input:    わかったら
--- expected: 心得たら
=== 心得る わかる 連用タ接続
--- input:    わかったよ
--- expected: 心得たなり
=== 心得る わかる 連用形
--- input:    わかりたい
--- expected: 心得たい

=== 詫びる 基本形
--- input:    謝る。
--- expected: 詫びる。
=== 詫びる 未然形
--- input:    謝ったら
--- expected: 詫びたら
=== 詫びる 連用タ接続
--- input:    謝ったよ
--- expected: 詫びたなり
=== 詫びる 連用形
--- input:    謝りたい
--- expected: 詫びたい

=== わびる 基本形
--- input:    あやまる。
--- expected: わびる。
=== わびる 未然形
--- input:    あやまったら
--- expected: わびたら
=== わびる 連用タ接続
--- input:    あやまったよ
--- expected: わびたなり
=== わびる 連用形
--- input:    あやまりたい
--- expected: わびたい

=== 動詞 -じる
--- input:    気配を感じる
--- expected: 気配を感ずる

=== 形容詞 -しい
--- input:    うれしい事件ですね。
--- expected: うれしき事件でござるな。
=== 形容詞 -しく
--- input:    うれしくなりますね。
--- expected: うれしゅうなりまするな。
=== 形容詞 -しい
--- input:    楽しい事件ですね。
--- expected: 楽しき事件でござるな。
=== 形容詞 -しく
--- input:    楽しくなりますね。
--- expected: 楽しゅうなりまするな。

=== ゆえ
--- input:    なので、
--- expected: ゆえに、
=== ゆえ
--- input:    それなので、
--- expected: それゆえに、

=== ぬ
--- input:    それはしない。
--- expected: それはせぬ。
=== ぬ 例外
--- input:    それはしないで。
--- expected: それはしないで。
=== ぬ
--- input:    それはならない。
--- expected: それはならぬ。
=== ぬ
--- input:    私は知らない。
--- expected: それがしは知らぬ。

=== ねば
--- input:    そうしなければならない。
--- expected: そうせねばならぬ。
=== ねば
--- input:    そうしなければ。
--- expected: そうせねば。

=== ござる
--- input:    おはよう。
--- expected: おはようでござる。
=== ござる 例外
--- input:    おはようございます。
--- expected: おはようございまする。

=== 「な」の補助
--- input:    そうなのね。
--- expected: そうなのだな。

=== アルファベット
--- input:    JR
--- expected: じぇいあーる
=== アルファベット
--- input:    ＡＳＥＡＮ
--- expected: あせあん
=== アルファベット
--- input:    Fuga
--- expected: えふゆーじーえー
=== アルファベット
--- input:    a-abc
--- expected: えい-えーびーしー
=== アルファベット
--- input:    1getずさー
--- expected: 一げっとずさー

=== 置換 候
--- input:    言葉が乱れています。
--- expected: 言葉が乱れており候。

=== 置換 ありがとう
--- input:    これはどうもありがとう。
--- expected: これはかたじけないでござる。
=== 置換 ありがとう
--- input:    これはありがとうございます。
--- expected: これはかたじけない。
