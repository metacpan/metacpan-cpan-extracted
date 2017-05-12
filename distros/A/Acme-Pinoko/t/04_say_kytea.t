use strict;
use warnings;
use utf8;
use Test::Requires qw/Text::KyTea/;
use Test::Base;
plan tests => 1 * blocks;

binmode Test::More->builder->$_ => ':utf8'
    for qw/output failure_output todo_output/;

use Acme::Pinoko;

my $pinoko = Acme::Pinoko->new(parser => 'Text::KyTea');

run
{
    my $block = shift;
    is($pinoko->say($block->input), $block->expected);
};


__DATA__

=== No change
--- input:    せっかくいいとこなのにぃ
--- expected: せっかくいいとこなのにぃ

=== No change
--- input:    やったー
--- expected: やったー

=== No change (アニメ版では変化するが漫画版では変化しない)
--- input:    先生
--- expected: 先生

=== No change
--- input:    ピノコ
--- expected: ピノコ

=== No change
--- input:    ちゃんとお食べ。残すなんてぜいたくよ
--- expected: ちゃんとお食べ。残ちゅなんてぜいたくよのさ

=== No change
--- input:    ラルゴ
--- expected: ラルゴ
--- SKIP 漫画版では変化しないが保留 (アニメ版では「ヤユゴ」に変わることもある？)

=== No change
--- input:    めいっぱいたいへーん
--- expected: めいっぱいたいへーん

=== No change
--- input:    早くのませて
--- expected: 早くのませて

=== No change
--- input:    つくえ
--- expected: つくえ

=== No change
--- input:    稼げばいいじゃないの
--- expected: 稼げばいいじゃないのよさ

=== No change
--- input:    おっかない
--- expected: おっかない

=== No change
--- input:    卵焼き
--- expected: 卵焼き

=== No change
--- input:    おこづかい
--- expected: おこづかい
--- SKIP 漫画版では変化しないが本来は「づ」が「じゅ」に変わるべきと考える

=== No change
--- input:    ルナルナ
--- expected: ルナルナ
--- SKIP 漫画版では変化しないが例外すぎるのでスキップ

=== No change
--- input:    あったかーい
--- expected: あったかーい

=== No change
--- input:    帰ってきて
--- expected: 帰ってきて

=== No change
--- input:    待ってたのよ
--- expected: 待ってたのよさ

=== No change
--- input:    犬のかわりなの
--- expected: 犬のかわりなの
--- SKIP り -> い になるべき

=== No change
--- input:    ポケット
--- expected: ポケット

=== No change
--- input:    あけていい？
--- expected: あけていい？

=== No change
--- input:    アッチョンブリケ
--- expected: アッチョンブリケ

=== No change
--- input:    アッチョンブリケー
--- expected: アッチョンブリケー

=== No change
--- input:    アッチョンブリケーー
--- expected: アッチョンブリケーー

=== No change
--- input:    アラマンチュ
--- expected: アラマンチュ

=== No change
--- input:    シーウーノアラマンチュ
--- expected: シーウーノアラマンチュ

=== No change
--- input:    かわいー
--- expected: かわいー

=== No change
--- input:    旅行のおみやげ
--- expected: 旅行のおみやげ

=== No change
--- input:    ビンも入ってたもんね
--- expected: ビンも入ってたもんね

=== No change
--- input:    ちがう
--- expected: ちがう

=== No change
--- input:    あの人の妹
--- expected: あの人の妹

=== No change
--- input:    ちっちゃーく
--- expected: ちっちゃーく

=== No change
--- input:    ひっぱたくとかみつく
--- expected: ひっぱたくとかみつく

=== No change
--- input:    させて
--- expected: させて

=== No change
--- input:    ヾ(^▽^*
--- expected: ヾ(^▽^*

=== Np change
--- input:    ＼(^o^)／
--- expected: ＼(^o^)／

=== No change
--- input: 777
--- expected: 777

=== No change
--- input:    ２０
--- expected: ２０

=== No change
--- input:    ishikawa
--- expected: ishikawa

=== No change
--- input:    ﾎシｰﾝ
--- expected: ﾎシｰﾝ

=== う -> ゆ
--- input:    思う
--- expected: 思ゆ
--- SKIP 滅多に変化しない

=== さ -> ちゃ
--- input:    お星さま
--- expected: お星ちゃま
--- SKIP KyTeaの読み推定誤りのため

=== さ -> ちゃ
--- input:    まさか
--- expected: まちゃか

=== さ -> ちゃ
--- input:    お魚
--- expected: おちゃかな

=== さ -> ちゃ, ろ -> よ
--- input:    ご苦労様
--- expected: ごくようちゃま

=== し -> ち
--- input:    知ってんだから
--- expected: ちってんらかや

=== し -> ち
--- input:    詳しく
--- expected: 詳ちく

=== し -> ち
--- input:    内緒
--- expected: ないちょ

=== し -> ち
--- input:    自信
--- expected: じちん

=== し -> ち
--- input:    オシッコ
--- expected: オチッコ

=== し -> ち
--- input:    死んだ
--- expected: ちんら

=== し -> ち
--- input:    モシモシ
--- expected: モチモチ

=== し -> ち
--- input:    お話ししたかった
--- expected: お話ちちたかった

=== し -> ち, ら -> や
--- input:    プライバシー
--- expected: プヤイバチー

=== し -> ち, る -> ゆ
--- input:    バカにしてるじゃんか
--- expected: バカにちてゆじゃんか

=== し -> ち, れ -> え
--- input:    話してくれなければ渡しません
--- expected: 話ちてくえなけえば渡ちません

=== じ -> じゅ
--- input:    真面目
--- expected: まじゅめ

=== じ -> じゅ
--- input:    はじめて
--- expected: はじゅめて

=== しゃ -> ちゃ
--- input:    いらっしゃい
--- expected: いやっちゃい

=== しゃ -> ちゃ
--- input:    ほうしゃのう
--- expected: ほうちゃのう

=== しゅ -> ちゅ
--- input:    シュークリーム
--- expected: チュークイーム

=== しゅ -> ちゅ
--- input:    助手で
--- expected: じょちゅれ

=== しょ -> ちょ
--- input:    見ましょ
--- expected: 見まちょ

=== しょ -> ちょ
--- input:    立派でしょ
--- expected: いっぱれちょ

=== しょ -> ちょ
--- input:    紹介
--- expected: ちょうかい

=== しょ -> ちょ
--- input:    お食事
--- expected: おちょくじ

=== しょう -> ちょ
--- input:    あてましょうか
--- expected: あてまちょう
--- SKIP 「しょ」のみ「ちょ」に変換されることも多いので保留

=== す -> ちゅ
--- input:    もうすぐ
--- expected: もうちゅぐ

=== す -> ちゅ
--- input:    行ってきます
--- expected: 行ってきまちゅ

=== す -> ちゅ
--- input:    座って
--- expected: ちゅわって

=== す -> ちゅ
--- input:    助けて
--- expected: たちゅけて

=== す -> ちゅ, り -> い
--- input:    ヒステリー
--- expected: ヒチュテイー

=== す -> ちゅ, る -> ゆ
--- input:    する
--- expected: ちゅゆ

=== す -> ち
--- input:    すごく
--- expected: ちごく
--- SKIP 「す」->「ちゅ」にほぼ統一されているため

=== ず -> じゅ
--- input:    絆
--- expected: きじゅな

=== ず -> じゅ
--- input:    恋煩い
--- expected: こいわじゅやい

=== ず -> じゅ
--- input:    ズボン
--- expected: ジュボン

=== ず -> ず
--- input:    ずーっと
--- expected: ずーっと

=== そ -> ちょ
--- input:    治そう
--- expected: 治ちょう
--- SKIP 「そ」->「ちょ」に変化しないパターンも多いので保留

=== そ -> ちょ
--- input:    かわいそう
--- expected: かわいちょう
--- SKIP 「そ」->「ちょ」に変化しないパターンも多いので保留

=== だ -> ら
--- input:    お友だちなの？
--- expected: お友らちなの？

=== だ -> ら
--- input:    だめ
--- expected: らめ

=== だ -> ら
--- input:    ちょうだい
--- expected: ちょうらい

=== だ -> ら
--- input:    お手伝い
--- expected: おてつらい

=== だ -> ら
--- input:    誰
--- expected: らえ

=== だ -> ら
--- input:    旦那
--- expected: らんな

=== だ -> ら
--- input:    なーんだ
--- expected: なーんら

=== だ -> だ
--- input:    だるくて
--- expected: だゆくて

=== だ -> だ
--- input:    だが
--- expected: だが

=== だ -> ら, です -> れちゅ
--- input:    だったんですって
--- expected: らったんれちゅって

=== づ -> じゅ
--- input:    小包
--- expected: こじゅつみ
--- SKIP KyTea が「小包」の読みを「こずつみ」と推定するため

=== づ -> じゅ
--- input:    こづつみ
--- expected: こじゅつみ

=== っつ -> っちゅ
--- input:    ガッツが足りない
--- expected: ガッチュが足いない

=== で -> れ
--- input:    とんでも
--- expected: とんれも

=== で -> れ
--- input:    まるで
--- expected: まゆれ

=== で -> れ, れ -> え
--- input:    バレンタインデー
--- expected: バエンタインレー

=== ど -> ろ
--- input:    ひどい
--- expected: ひろい

=== ど -> ろ
--- input:    気の毒に
--- expected: 気のろくに

=== ど -> ろ
--- input:    時々
--- expected: ときろき

=== の -> ん
--- input:    巣の中
--- expected: 巣ん中
--- SKIP ルールが明確でない

=== の -> ん
--- input:    生まれたのよ
--- expected: 生まえたんよ
--- SKIP ルールが明確でない

=== ら -> や
--- input:    泳ぎたいくらい
--- expected: 泳ぎたいくやい

=== ら -> や
--- input:    わからない
--- expected: わかやない

=== ら -> や
--- input:    うらめしそう
--- expected: うやめちそう

=== ら -> や
--- input:    嫌われちゃう
--- expected: きやわえちゃう

=== ら -> や, し -> ち
--- input:    シラコ
--- expected: チヤコ

=== り -> い
--- input:    はっきりして
--- expected: はっきいちて

=== り -> い
--- input:    お守り
--- expected: お守い

=== る -> ゆ
--- input:    やるな
--- expected: やゆな

=== る -> ゆ
--- input:    悪い
--- expected: わゆい

=== る -> ゆ
--- input:    送る
--- expected: 送ゆ

=== る -> ゆ
--- input:    許せない
--- expected: ゆゆせない

=== る -> ゆ
--- input:    セル
--- expected: セユ

=== ル -> ユ
--- input:    アルバム
--- expected: アユバム

=== れ -> え
--- input:    きれー
--- expected: きえー

=== れ -> え
--- input:    それ
--- expected: そえ

=== れ -> え
--- input:    テレビ
--- expected: テエビ

=== れ -> え, さ -> ちゃ, る -> ゆ
--- input:    殺される
--- expected: こよちゃえゆ

=== れ -> え, し -> ち
--- input:    してくれれば
--- expected: ちてくええば

=== れ -> え, る -> ゆ
--- input:    倒れてる
--- expected: 倒えてゆ

=== ら -> や, れ -> え, る -> ゆ
--- input:    しばられてる
--- expected: ちばやえてゆ

=== ろ -> よ
--- input:    そろそろ
--- expected: そよそよ

=== ろ -> よ
--- input:    泥棒
--- expected: どよぼう

=== ろ -> よ
--- input:    お風呂
--- expected: おふよ

=== です -> れちゅ
--- input:    おそいです
--- expected: おそいれちゅ

=== です -> れちゅ
--- input:    いいですか
--- expected: いいれちゅか

=== のです -> のれちゅ
--- input:    地が黒いのです(＃￣З￣)
--- expected: 地がくよいのれちゅ(＃￣З￣)

=== ですね -> れちゅね
--- input:    感謝ですね
--- expected: かんちゃれちゅね

=== でしょ -> れちょ
--- input:    おそいでしょ
--- expected: おそいれちょ

=== でしょ -> れちょ
--- input:    片思いでしょ
--- expected: 片思いれちょ

=== でしょｘ２ -> れちょｘ２
--- input:    冒険でしょでしょ
--- expected: 冒険れちょれちょ

=== でしょ -> れちょ, る -> ゆ
--- input:    上手く受けるでしょ
--- expected: 上手く受けゆれちょ

=== しゅじゅつ -> しうつ
--- input:    主述
--- expected: しうつ

=== 手術 -> シウツ
--- input:    手術が成功
--- expected: シウツが成功

=== 憂鬱 -> ユーツ
--- input:    憂鬱
--- expected: ユーツ

=== 抜群 -> ばちぐん
--- input:    抜群
--- expected: バチグン

=== キス -> キチュ
--- input:    キス
--- expected: キチュ

=== あのね -> あんね
--- input:    あのね
--- expected: あんね

=== それで -> そいれ
--- input:    それでどうなったの
--- expected: そいれろうなったのよさ

=== こども -> こよも
--- input:    こども
--- expected: こよも

=== なんだ -> なんや
--- input:    なんだか
--- expected: なんやか

=== うそつき -> うそちゅき
--- input:    ウソツキ
--- expected: ウソチュキ

=== 1人 -> ひとい
--- input:    1人
--- expected: ひとい

=== １８歳 -> １８ちゃい
--- input:    １８歳
--- expected: １８ちゃい

=== 奥さん -> おくたん
--- input:    奥さんです
--- expected: おくたんれちゅ

=== レディ -> レレイ
--- input:    レディなのよ
--- expected: レレイなのよさ

=== レディー? -> レレイ
--- input:    レディーなのよ
--- expected: レレイなのよさ

=== レディー? -> レレイ
--- input:    レディーーなのよ
--- expected: レレイーなのよさ

=== ﾚﾃﾞｨ -> ﾚﾚｲ
--- input:    ﾋﾟﾉｺはﾚﾃﾞｨです
--- expected: ﾋﾟﾉｺはﾚﾚｲれちゅ

=== キャンディー? -> キャンレー
--- input:    キャンディ
--- expected: キャンレー

=== キャンディー? -> キャンレー
--- input:    キャンディー
--- expected: キャンレー

=== キャンディー? -> キャンレー
--- input:    キャンディーー
--- expected: キャンレーー

=== アクセサリ -> アクチェチャイ
--- input:    アクセサリ
--- expected: アクチェチャイ

=== アクセサリー -> アクチェチャイー
--- input:    アクセサリー
--- expected: アクチェチャイー

=== 了解 -> アラマンチュ
--- input:    了解
--- expected: アラマンチュ
--- SKIP この解釈はアニメ版限定なので

=== そりゃあ -> そやァ
--- input:    そりゃあ
--- expected: そやァ

=== そりゃー -> そやァ
--- input:    そりゃー
--- expected: そやァ

=== 〜の -> 〜のよさ
--- input:    行くの
--- expected: 行くのよさ

=== 〜の！ -> 〜のよさ！
--- input:    行くの！
--- expected: 行くのよさ！

=== 〜の! -> 〜のよさ!
--- input:    行くの!
--- expected: 行くのよさ!

=== 〜の。 -> 〜のよさ。
--- input:    行くの。
--- expected: 行くのよさ。

=== 〜のよ -> 〜のよさ
--- input:    いいじゃないのよ
--- expected: いいじゃないのよさ

=== 〜のよ＋半角スペース -> 〜のよさ＋半角スペース
--- input eval
"いいじゃないのよ "
--- expected eval
"いいじゃないのよさ "

=== 〜のよ＋全角スペース -> 〜のよさ＋全角スペース
--- input eval
"いいじゃないのよ　"
--- expected eval
"いいじゃないのよさ　"

=== 〜のよ・・ -> 〜のよさ・・
--- input:    いいじゃないのよ・・
--- expected: いいじゃないのよさ・・

=== 〜のよ･･ -> 〜のよさ･･
--- input:    いいじゃないのよ･･
--- expected: いいじゃないのよさ･･

=== 〜のよ‥ -> 〜のよさ‥
--- input:    いいじゃないのよ‥
--- expected: いいじゃないのよさ‥

=== 〜のよ… -> 〜のよさ…
--- input:    いいじゃないのよ…
--- expected: いいじゃないのよさ…

=== 〜のよ。 -> 〜のよさ。
--- input:    いいじゃないのよ。
--- expected: いいじゃないのよさ。

=== 〜のよ｡ -> 〜のよさ｡
--- input:    いいじゃないのよ｡
--- expected: いいじゃないのよさ｡

=== 〜のよ. -> 〜のよさ.
--- input:    いいじゃないのよ.
--- expected: いいじゃないのよさ.

=== 〜のよ． -> 〜のよさ．
--- input:    いいじゃないのよ．
--- expected: いいじゃないのよさ．

=== 〜のよ　 -> 〜のよさ　
--- input:    いいじゃないのよ　
--- expected: いいじゃないのよさ　

=== 生野 -> No のよさ
--- input:    生野
--- expected: 生野

=== の＋形容詞 -> No のよさ
--- input:    どれくらいの高さ
--- expected: ろえくやいの高ちゃ

=== の＋助動詞 -> No のよさ
--- input:    吐き気しかしないのだけど
--- expected: 吐き気ちかちないのらけよ

=== の＋連体詞 -> No のよさ
--- input:    3セット目のあの流れ
--- expected: 3セット目のあの流え

=== の＋動詞 -> No のよさ
--- input:    彼のやりすぎ
--- expected: かえのやいちゅぎ

=== の＋副詞 -> No のよさ
--- input:    自分のそういうとこ
--- expected: 自分のそういうとこ

=== の＋形状詞 -> No のよさ
--- input:    もののようで
--- expected: もののようれ

=== の＋代名詞 -> No のよさ
--- input:    あれのそれ
--- expected: あえのそえ

=== の＋接頭詞 -> No のよさ
--- input:    トロンボーンの主旋律
--- expected: トヨンボーンのちゅせんいつ

=== の＋接頭詞 -> No のよさ
--- input:    ただのおでぶちゃん
--- expected: たらのおれぶちゃん

=== 名詞＋の＋スペース -> No のよさ
--- input:    Perlの Perl
--- expected: Perlの Perl

=== 名詞＋の -> No のよさ
--- input:    Perlの
--- expected: Perlの

=== の＋終端じゃない記号 -> No のよさ
--- input:    Perlの「ハッシュ」
--- expected: Perlの「ハッチュ」

=== 〜だよ -> 〜だのよ
--- input:    ゴキブリ以下だよ
--- expected: ゴキブイ以下だのよ

=== 〜だよ！ -> 〜だのよ！
--- input:    ゴキブリ以下だよ！
--- expected: ゴキブイ以下だのよ！

=== 〜だよ\n -> 〜だのよ\n
--- input eval
"ゴキブリ以下だよ\n"
--- expected eval
"ゴキブイ以下だのよ\n"

=== 〜だよ\t -> 〜だのよ\t
--- input eval
"ゴキブリ以下だよ\t"
--- expected eval
"ゴキブイ以下だのよ\t"

=== 〜ね -> 〜ね
--- input:    気をつけてね
--- expected: 気をつけてね

=== 〜よ -> 〜よのさ
--- input:    並んでる人よ
--- expected: なやんれゆ人よのさ

=== 〜よ -> 〜よのさ
--- input:    しっかりやりましょうよ
--- expected: ちっかいやいまちょうよのさ

=== 〜よね -> 〜よのね
--- input:    きれいよね
--- expected: きえいよのね

=== 〜わ -> 〜わのよ
--- input:    書くわ
--- expected: 書くわのよ
--- SKIP 「わのね」か「わのよ」かはランダム

=== 〜わ -> 〜わのね
--- input:    失敬しちゃうわ
--- expected: ちっけいしちゃうわのね
--- SKIP 「わのね」か「わのよ」かはランダム

=== 〜わよ -> 〜わのよ
--- input:    するわよ
--- expected: ちゅゆわのよ
--- SKIP KyTea の品詞タグ付け誤りによる

=== 〜わね -> 〜わのね
--- input:    失敬しちゃうわね
--- expected: ちっけいしちゃうわのね
--- SKIP KyTea の品詞タグ付け誤りによる

=== 〜なのよね -> 〜なのよのね
--- input:    ピノコなのよね
--- expected: ピノコなのよのね

=== 〜のよ -> 〜のよさ
--- input:    なんのよ
--- expected: なんのよさ

=== 〜のよね -> 〜のよね
--- input:    したかったのよね
--- expected: ちたかったのよね

=== 〜したらどうなの -> 〜ちたやろうなのよさ
--- input:    ほげほげしたらどうなの
--- expected: ほげほげちたやろうなのよさ

=== ｗｗｗｗｗｗｗｗｗｗｗｗ
--- input:    思ってるよｗ
--- expected: 思ってゆよのさｗ

=== ｗｗｗｗｗｗｗｗｗｗｗｗ
--- input:    思ってるよｗｗ
--- expected: 思ってゆよのさｗｗ

=== 固有名詞
--- input:    テレビ愛知
--- expected: テエビ愛知

=== ヶ
--- input:    一ヶ月
--- expected: 一ヶ月

=== ヶ
--- input:    桐ヶ谷
--- expected: きいがや

=== ケ
--- input:    桐ケ谷
--- expected: きいがや

=== ヵ
--- input:    一ヵ月
--- expected: 一ヵ月

=== 中３
--- input:    子も中３なの
--- expected: 子もちゅうちゃんなのよさ

=== ３月
--- input:    ３月
--- expected: ちゃんがつ
--- SKIP 「さん」と読まれないため

=== LOW LINE
--- input:    研_3月
--- expected: 研_3月

=== FULL WIDTH LOW LINE
--- input:    研＿3月
--- expected: 研＿3月

=== 長音化阻止
--- input:    言い聞かせる
--- expected: 言い聞かせゆ

=== づ -> じゅ
--- input:    顔を近づけて
--- expected: 顔を近じゅけて
