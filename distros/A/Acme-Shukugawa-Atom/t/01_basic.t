use Test::Base;
use utf8;

plan tests => 1 + 1 * blocks;

use_ok("Acme::Shukugawa::Atom");


sub translate {
    Acme::Shukugawa::Atom->translate(shift);
}

filters {
    input => 'translate',
};

run_is;

__DATA__

===
--- input:    六本木の胸の大きいお姉さんがいる店を予約した
--- expected: ギロッポンのパイオツカイデーチャンネーがルーイーセーミーをバミった

===
--- input:    ハワイ
--- expected: ワイハー

===
--- input:    寿司
--- expected: シースー

===
--- input:    銀座で午前0時に寿司行こう
--- expected: ザギンでテッペンにシースーコウイー

===
--- input:    狼
--- expected: カミオー

===
--- SKIP
# mecabの辞書にない？
--- input:    鋏
--- expected: サミハー

===
--- input:    おばあさんの口はどうして大きいの？
--- expected: チャンバーのチークーはどうしてカイデー？

===
--- input:    おばあさんの耳はどうして大きいの？
--- expected: チャンバーのミーミーはどうしてカイデー？

===
--- input:    別にdankogaiはエヌジーというわけではない
--- expected: ジリサワゴネタガイダンコはジーエヌというケーワーではない

===
--- input:    びっくり
--- expected: クリビツ

===
--- input:    赤ずきんちゃん
--- expected: ズキアカのチャンネー

===
--- input:    屁
--- expected: エーヘー

===
--- input:    火
--- expected: イーヒー

===
--- input:    金槌
--- expected: ナグリ

===
--- input:    抱き合わせ
--- expected: バーター

===
--- input:    編集
--- expected: つまむ

===
--- input:    斜め
--- expected: ヤオヤ

===
--- input:    ギターは下手ですが歌は上手です
--- expected: ターギーはターヘーですがターウーはマイウーです

===
--- SKIP
# 上手が「うわて」なのか「かみて」なのか「じょうず」なのかわからんので
# 今ちょっと無理＞＜
--- input:    ステージの下手から上手に片付け
--- expected: ジーステのしもてからかみてにわらう

===
--- input:    納期
--- expected: ケツカッチン

===
--- input:    締め切り
--- expected: ケツカッチン

===
# このまま採用するのは危険な気がする。活用とかで判断した方が良い？
--- SKIP
--- input:    往復
--- expected: 行って来い

===
--- input:    見上げ
--- expected: あおり

===
--- input:    決定
--- expected: フィックス

===
--- input:    予備
--- expected: 押さえ

===
--- input:    食べ物 既存
--- expected: 消えもの 有りもの

===
--- input:    ガムテープ
--- expected: ガバチョ

===
--- input:    収容
--- expected: キャパ

===
--- input:    長さ
--- expected: 尺

===
--- input:    照明を当てる
--- expected: メイショーをうつ

===
--- input:    食費 交通費
--- expected: アゴ アシ

===
--- input:    フジテレビ ニッポン放送 テレビ東京 文化放送 日本テレビ
--- expected: CX LF TX QR 日テレ

===
# エフコマが分からない・・・
--- SKIP
--- input:    「ウェブ時代 5つの定理」も四コママンガに
--- expected: 「ブーウェーダイジー ゲーつのイリテー」もエフコマガーマンに

===
--- SKIP
--- input:    累計70万部突破とモノ書きサバティカル
--- expected: ケイルイハー十万部パツトーとノーモーキーガーサバティカル

===
--- SKIP
--- input:    ジャック、12歳。おめでとう!
--- expected: ツクジャ、ツェー十デー歳。デトーオメ!

===
--- SKIP
--- input:    産経新聞一面連載が完結、ぜんぶまとめてウェブで読めます。
--- expected: ケーサンブンシンツェー面サイレンがケツカン、オールバーターでブーウェーでマスヨメ。

===
--- SKIP
--- input:    千円
--- expected: ツェー千円

===
--- SKIP
--- input:    1000円
--- expected: ツェー千円

===
--- SKIP
--- input:    二万円
--- expected: デー万円

===
--- SKIP
--- input:    27000円
--- expected: デー万ハー千円

===
--- SKIP
--- input:    三万四千円
--- expected: エー万エフ千円

===
--- SKIP
--- input:    十五万六千円
--- expected: ツェーじゅうゲー万アー千円

===
--- SKIP
--- input: 今度のアシスタントは時間がなくてかなり駄目なのになってしまいました
--- expected: hoge
