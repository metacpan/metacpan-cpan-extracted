use strict;
use warnings;
use Test::Base;
plan tests => 1 * blocks;

use utf8;
binmode Test::More->builder->$_ => ':utf8'
    for qw(output failure_output todo_output);

use Acme::Ikamusume;

filters { match => 'regexp' };

run {
    my $block = shift;
    
    my $output = Acme::Ikamusume->geso($block->input);
    my $title = $block->name ." input: ". $block->input;
    
    if ($block->match) {
        like($output, $block->match, $title);
    } else {
        is($output, $block->expected, $title);
    }
};

__DATA__
=== SYNOPSIS
--- input:    イカ娘です。あなたもperlで侵略しませんか？
--- expected: イカ娘でゲソ。お主もperlで侵略しなイカ？


=== IKA: replace
--- input:    以下のように
--- expected: イカのように
=== IKA: replace
--- input:    海からの使者、イカ娘でゲソ
--- expected: 海からの使者、イカ娘でゲソ
=== IKA: replace
--- input:    西瓜でゲソ
--- expected: すイカでゲソ
=== IKA: replace
--- input:    いかんでゲソ
--- expected: イカんでゲソ
=== IKA: replace
--- input:    ハイカラでゲソ
--- expected: ハイカラでゲソ
=== IKA: replace
--- input:    侵略しないか。
--- expected: 侵略しなイカ。
=== IKA: replace
--- input:    侵略じゃないか。
--- expected: 侵略じゃなイカ。
=== IKA: replace
--- input:    侵略しないかと
--- expected: 侵略しなイカと
=== IKA: replace
--- input:    徘徊完了
--- expected: はイカイカんりょうでゲソ
=== IKA: replace
--- input:    いい感じ無敵にススメ
--- expected: イーカんじ無敵にススメ
=== IKA: replace
--- input:    いー感じ無敵にススメ
--- expected: イーカんじ無敵にススメ
=== IKA: replace
--- input:    言い方
--- expected: イーカたでゲソ
=== IKA: replace
--- input:    いいか
--- expected: いイカ


=== IKA: IIKA
--- input:    いいか？
--- expected: いイカ？
=== IKA: IIKA
--- input:    いいですか？
--- expected: いイカ？
=== IKA: IIKA
--- input:    いいでしょうか？
--- expected: いイカ？


=== GESO: replace
--- input:    そうでげそ
--- expected: そうでゲソ
=== GESO: replace
--- input:    凧揚げ僧侶
--- expected: 凧あゲソうりょでゲソ


=== GESO: userdic
--- input:    イカ娘です。
--- expected: イカ娘でゲソ。
=== GESO: userdic
--- input:    イカ娘ですから、
--- expected: イカ娘でゲソから、
=== IKA: userdic
--- input:    イカ娘ですね。
--- expected: イカ娘じゃなイカ。
=== IKA: userdic
--- input:    イカ娘ですよね。
--- expected: イカ娘じゃなイカ。
=== IKA: usedic
--- input:    イカ娘でしょうか？
--- expected: イカ娘じゃなイカ？


=== IKA/GESO DA = GESO
--- input:    イカ娘だ
--- expected: イカ娘でゲソ
=== IKA/GESO DA = GESO
--- input:    イカ娘だから
--- expected: イカ娘でゲソから
=== IKA/GESO DA = GESO
--- input:    イカ娘だが、
--- expected: イカ娘でゲソが、
=== IKA/GESO DA + ゼ終助詞 = IKA
--- reported: http://twitter.com/k_e_i_65/status/13634663557898240
--- input:    イカ娘だぜ
--- expected: イカ娘じゃなイカ
=== IKA/GESO DA + ゼ終助詞 = IKA
--- input:    イカ娘だぜよ
--- expected: イカ娘じゃなイカ
=== IKA/GESO DA + ゾ終助詞 = GESO
--- input:    イカ娘だぞ
--- expected: イカ娘でゲソ
=== IKA/GESO DA + ゾ終助詞 = GESO
--- input:    イカ娘だぞ
--- expected: イカ娘でゲソ
=== IKA/GESO DA + ゾ終助詞 = GESO
--- input:    イカ娘だぞい
--- expected: イカ娘でゲソ
=== IKA/GESO DA + ゾ終助詞 = GESO
--- input:    イカ娘だぞよ
--- expected: イカ娘でゲソ
=== IKA/GESO DA + ナ終助詞 = IKA
--- input:    イカ娘だな
--- expected: イカ娘じゃなイカ
=== IKA/GESO DA + ナ終助詞 = IKA
--- input:    イカ娘だなあ
--- expected: イカ娘じゃなイカ
=== IKA/GESO DA + ナ終助詞 = IKA
--- input:    イカ娘だなぁ
--- expected: イカ娘じゃなイカ
=== IKA/GESO DA + ナ終助詞 = IKA
--- input:    イカ娘だね
--- expected: イカ娘じゃなイカ
=== IKA/GESO DA + ナ終助詞 = IKA
--- input:    イカ娘だねえ
--- expected: イカ娘じゃなイカ
=== IKA/GESO DA + ナ終助詞 = IKA
--- input:    イカ娘だねぇ
--- expected: イカ娘じゃなイカ
=== IKA/GESO DA + ナ終助詞 = IKA
--- input:    イカ娘だのう
--- expected: イカ娘じゃなイカ
=== IKA/GESO DA + ヨ終助詞 = IKA
--- input:    イカ娘だよ
--- expected: イカ娘じゃなイカ
=== IKA/GESO DA + ヨ終助詞 = IKA
--- input:    イカ娘だよな
--- expected: イカ娘じゃなイカ
=== IKA/GESO DA + ヨ終助詞 = IKA
--- input:    イカ娘だよね
--- expected: イカ娘じゃなイカ
=== IKA/GESO DA + ワ終助詞 = IKA
--- input:    イカ娘だわ
--- expected: イカ娘じゃなイカ
=== IKA/GESO DA + ワ終助詞 = IKA
--- input:    イカ娘だわい
--- expected: イカ娘じゃなイカ
=== IKA/GESO DA + ワ終助詞 = IKA
--- input:    イカ娘だわね
--- expected: イカ娘じゃなイカ


=== IKA: userdic (+ IKA replace)
--- input:    イカ娘だろうか。
--- expected: イカ娘じゃなイカ。


=== GESO: userdic
--- input:    イカ娘である
--- expected: イカ娘でゲソ
=== GESO: userdic
--- input:    イカ娘であるが、
--- expected: イカ娘でゲソが、
=== GESO: userdic
--- input:    イカ娘で、あるが、
--- expected: イカ娘で、あるでゲソが、
=== IKA: userdic
--- input:    そうかな。
--- expected: そうじゃなイカ。
=== IKA: userdic
--- input:    そうかなと。
--- expected: そうじゃなイカと。


=== IKA/GESO: inflection 名詞+
--- input:    お店か
--- expected: お店じゃなイカ
=== IKA/GESO: inflection 副詞+
--- input:    まだか
--- expected: まだでゲソか
=== IKA/GESO: inflection 動詞（基本形）+
--- input:    走るか？
--- expected: 走るでゲソか？
=== IKA/GESO: inflection 動詞（その他）+
--- input:    走りませんか？
--- expected: 走らなイカ？
=== IKA/GESO: inflection です +
--- input:    イカ娘ですか？
--- expected: イカ娘じゃなイカ？


=== IKA: inflection 五段
--- input:    歩きませんか？
--- expected: 歩かなイカ？
=== IKA: inflection 五段
--- input:    泳ぎませんか？
--- expected: 泳がなイカ？
=== IKA: inflection 五段
--- input:    探しませんか？
--- expected: 探さなイカ？
=== IKA: inflection 五段
--- input:    勝ちませんか？
--- expected: 勝たなイカ？
=== IKA: inflection 五段
--- input:    死にませんか？
--- expected: 死ななイカ？
=== IKA: inflection 五段
--- input:    遊びませんか？
--- expected: 遊ばなイカ？
=== IKA: inflection 五段
--- input:    知りませんか？
--- expected: 知らなイカ？
=== IKA: inflection 五段
--- input:    笑いませんか？
--- expected: 笑わなイカ？

=== IKA: inflection 上一段
--- input:    いませんか？
--- expected: いなイカ？
=== IKA: inflection 上一段
--- input:    起きませんか？
--- expected: 起きなイカ？
=== IKA: inflection 上一段
--- input:    すぎませんか？
--- expected: すぎなイカ？
=== IKA: inflection 上一段
--- input:    閉じませんか？
--- expected: 閉じなイカ？
=== IKA: inflection 上一段
--- input:    落ちませんか？
--- expected: 落ちなイカ？
=== IKA: inflection 上一段
--- input:    浴びませんか？
--- expected: 浴びなイカ？
=== IKA: inflection 上一段
--- input:    しみませんか？
--- expected: しみなイカ？
=== IKA: inflection 上一段
--- input:    ふりませんか？
--- expected: ふらなイカ？

=== IKA: inflection 下一段
--- input:    見えませんか？
--- expected: 見えなイカ？
=== IKA: inflection 下一段
--- input:    受けませんか？
--- expected: 受けなイカ？
=== IKA: inflection 下一段
--- input:    告げませんか？
--- expected: 告げなイカ？
=== IKA: inflection 下一段
--- input:    見せませんか？
--- expected: 見せなイカ？
=== IKA: inflection 下一段
--- input:    混ぜませんか？
--- expected: 混ぜなイカ？
=== IKA: inflection 下一段
--- input:    捨てませんか？
--- expected: 捨てなイカ？
=== IKA: inflection 下一段
--- input:    茹でませんか？
--- expected: 茹でなイカ？
=== IKA: inflection 下一段
--- input:    寝ませんか？
--- expected: 寝なイカ？
=== IKA: inflection 下一段
--- input:    経ませんか？
--- expected: 経なイカ？
=== IKA: inflection 下一段
--- input:    食べませんか？
--- expected: 食べなイカ？
=== IKA: inflection 下一段
--- input:    求めませんか？
--- expected: 求めなイカ？
=== IKA: inflection 下一段
--- input:    入れませんか？
--- expected: 入れなイカ？

=== IKA: inflection カ変
--- input:    来ませんか？
--- expected: 来なイカ？
=== IKA: inflection サ変
--- input:    しませんか？
--- expected: しなイカ？


=== IKA: inflection ましょう
--- input:    しましょう！
--- expected: しなイカ！
=== IKA: inflection ましょうよ
--- input:    しましょうよ！
--- expected: しなイカ！


=== GESO: eos EOS
--- input:    わかった
--- expected: わかったでゲソ

=== GESO: eos + 記号（句点）
--- input:    わかった。
--- expected: わかったでゲソ。
=== GESO: eos + 記号（括弧閉）
--- input:    （ふむふむ）
--- expected: （ふむふむでゲソ）
=== GESO: eos + 記号（一般GESO可）
--- input:    なんと？　ああ　びっくり！
--- expected: なんとでゲソ？　ああ　びっくりでゲソ！
=== GESO: eos + 記号（一般GESO可）
--- input:    ふむふむ…ふむふむ‥ふむふむ～
--- expected: ふむふむでゲソ…ふむふむでゲソ‥ふむふむでゲソ～
--- SKIP
=== GESO: eos + 記号（一般GESO可）
--- input:    キャー☆　キャー★
--- expected: キャーでゲソ☆　キャーでゲソ★
=== GESO: eos + 記号 その他 no-op
--- input:    シンディー・ハリス※クラーク→マーティン＆
--- expected: シンディー・ハリス※クラーク→マーティン＆

=== GESO: eos + 記号 no-op
--- input:    今日は、いい天気。
--- expected: 今日は、いい天気でゲソ。

=== GESO: eos GESO/IKA no-op
--- input:    わかったでゲソ。
--- expected: わかったでゲソ。
=== GESO: eos GESO+IKA no-op
--- input:    いいじゃなイカ。
--- expected: いいじゃなイカ。

=== GESO: eos is その他 no-op
--- input:    かんたァ
--- expected: かんたァ
=== GESO: eos is フィラー
--- input:    えーっと
--- expected: えーっとでゲソ
=== GESO: eos is 感動詞
--- input:    へぇ
--- expected: へぇでゲソ
=== GESO: eos is 形容詞
--- input:    おかしい
--- expected: おかしいでゲソ
=== GESO: eos is 助詞 no-op
--- input:    人類へ
--- expected: 人類へ
=== GESO: eos is 助動詞
--- input:    そうすべし
--- expected: そうすべしでゲソ
=== GESO: eos is GESO/IKA + 助動詞
--- input:    ゲソね
--- expected: ゲソね
=== GESO: eos is 接続詞 no-op
--- input:    すると
--- expected: すると
=== GESO: eos is 接続詞 で no-op
--- input:    で
--- expected: で
=== GESO: eos is 接頭詞 no-op
--- input:    全。
--- expected: 全。
=== GESO: eos is 動詞
--- input:    泳ぐ
--- expected: 泳ぐでゲソ
=== GESO: eos is 副詞
--- input:    ひょっこり
--- expected: ひょっこりでゲソ
=== GESO: eos is 名詞
--- input:    海
--- expected: 海でゲソ
=== GESO: eos is 連体詞 no-op
--- input:    恐るべき、
--- expected: 恐るべき、


=== IKA: eos NAI
--- input:    そうじゃない
--- expected: そうじゃなイカ
=== IKA: eos NAI
--- input:    いいんじゃない？
--- expected: いいんじゃなイカ？


=== HTML tweak
--- input:    <p>君に届け</p>
--- expected: <p>お主に届けでゲソ</p>


=== EBI: accent
--- input: 海老蔵が襲名した
--- match: 海老.+蔵が襲名した
=== EBI: accent
--- input: えびな市
--- match: えび.+な市
=== EBI: accent
--- input: 今日はエビフライ
--- match: 今日はエビ.+フライ
=== EBI: accent
--- reportby: http://twitter.com/Yuichirou/status/13872045712482306
--- input: 名古屋と言えばエビフリャー
--- match: 名古屋と言えばエビ.+フリャー
--- SKIP


=== formal MASU 基本形 to casual 五段
--- input:    今やります。
--- expected: 今やるでゲソ。
=== formal MASU 基本形 to casual 五段 + 助詞 / GESO eos
--- input:    言いますか。
--- expected: 言うでゲソか。
=== formal MASU 基本形 to casual 上一段
--- input:    います。
--- expected: いるでゲソ。
=== formal MASU 基本形 to casual 上一段 + 助詞 / GESO eos
--- input:    いますか。
--- expected: いるでゲソか。
=== formal MASU 基本形 to casual 下一段
--- input:    見えます。
--- expected: 見えるでゲソ。
=== formal MASU 基本形 to casual 下一段 + 助詞 / GESO eos
--- input:    見えますか。
--- expected: 見えるでゲソか。
=== formal MASU 基本形 to casual カ変
--- input:    来ます。
--- expected: 来るでゲソ。
=== formal MASU 基本形 to casual カ変 + 助詞 / GESO eos
--- input:    来ますか。
--- expected: 来るでゲソか。
=== formal MASU 基本形 to casual サ変
--- input:    します。
--- expected: するでゲソ。
=== formal MASU 基本形 to casual サ変 + 助詞 / GESO eos
--- input:    しますか。
--- expected: するでゲソか。

=== formal MASU 連用形 to casual 五段
--- input:    書きました。
--- expected: 書いたでゲソ。
--- SKIP
=== formal MASU 連用形 to casual 五段
--- input:    やりました。
--- expected: やったでゲソ。
--- SKIP
=== formal MASU 連用形 to casual 下一
--- input:    受けました。
--- expected: 受けたでゲソ。
=== formal MASU 連用形 to casual 上一
--- input:    起きました。
--- expected: 起きたでゲソ。
=== formal MASU 連用形 to casual カ変
--- input:    来ました。
--- expected: 来たでゲソ。
=== formal MASU 連用形 to casual サ変
--- input:    しました。
--- expected: したでゲソ。


=== formal to casual userdic
--- input:    そうでした。
--- expected: そうだったでゲソ。


=== IKA: IKAN
--- input:    いけないでしょ
--- expected: イカんでしょ
=== IKA: IKAN
--- input:    それはいけないですね
--- expected: それはイカんじゃなイカ
=== IKA: IKAN
--- input:    それはいけませんね
--- expected: それはイカんね


=== rephrase simply
--- input:    それはありません。
--- expected: それはないでゲソ。


=== no honorific
--- input:    栄子ちゃんです
--- expected: 栄子でゲソ
=== no honorific
--- input:    たけるくんです
--- expected: たけるでゲソ
=== no honorific
--- input:    千鶴さんです
--- expected: 千鶴でゲソ
=== no honorific / unknown
--- input:    Cindyさんです
--- expected: Cindyでゲソ
=== no honorific / myself
--- input:    イカ娘様と呼びませんか
--- expected: イカ娘様と呼ばなイカ


=== userdic: お主
--- input:    あなたは
--- expected: お主は
=== userdic: お主
--- input:    あんたは
--- expected: お主は
=== userdic: お主
--- input:    貴方は
--- expected: お主は
=== userdic: お主
--- input:    お前は
--- expected: お主は
=== userdic: お主
--- input:    おまえは
--- expected: お主は
=== userdic: お主
--- input:    そちは
--- expected: お主は
=== userdic: お主
--- input:    君は
--- expected: お主は
=== userdic: お主
--- input:    キミは
--- expected: お主は
=== userdic: お主
--- input:    きみは
--- expected: お主は

=== GESO: interjection
--- input:    あはははは
--- expected: ゲソソソ
--- SKIP

