use strict;
use utf8;
use Test::Base;

plan tests => 1 * blocks;

use Acme::Lou;

my $lou = Acme::Lou->new;

run {
    my $block = shift;
    is(
        $lou->translate($block->input),
        $block->expected,
        $block->name
    );
};

__DATA__

=== basic 
--- input
今年もよろしくお願いいたします。
--- expected 
ディスイヤーもよろしくプリーズいたします。

=== basic 
--- input
ルーと一緒です。
--- expected 
ルーとトゥギャザーです。

=== basic 
--- quote: http://www.kantei.go.jp/jp/abespeech/2007/01/04kaiken.html
--- input
美しい国づくりの礎を築くことができたと、考えています。
--- expected 
ビューティフルなカントリーづくりのファンデーションストーンをビルドすることができたと、シンクアバウトしています。

=== adnominal 
--- input
それ、どんな返事？
--- expected
それ、ホワットリプライ？

=== verb 5-dan
--- input
変わらない。変わります。変わる。
--- expected
変わらない。チェンジします。チェンジする。

=== verb 5-dan
--- input
変わる、変われば、変わろう。変われ。
--- expected
チェンジする、チェンジすれば、変わろう。チェンジ。

=== verb kami-1
--- input
閉じない。いや、閉じます。閉じる。
--- expected
閉じない。いや、クローズします。クローズする。

=== verb kami-1
--- input
閉じるとき、閉じれば閉じよ！
--- expected
クローズするとき、クローズすればクローズ！

=== verb shimo-1
--- input
調べない。かなり激しく調べます。
--- expected
調べない。かなりヴァイオレントにチェックアップします。

=== verb shimo-1
--- input
調べる。調べるとき調べれば調べろ！
--- expected
チェックアップする。チェックアップするときチェックアップすればチェックアップ！

=== adj
--- input
忙しければ忙しい。忙しかったなら忙しかろう。
--- expected
ビジーならばビジー。ビジーだったならビジーだろう。

=== adj
--- input
忙しく忙しいと、忙しいかわからない。
--- expected
ビジーにビジーと、ビジーかわからない。

=== adj2
--- input
同じなら同じだって同じで同じだろ。
--- expected
セイムならセイムだってセイムでセイムだろ。

=== adj2
--- input
同じな同じに、同じだ。
--- expected
セイムなセイムに、セイムだ。

=== prefix fix
--- input
お時間をありがとうございます。
--- expected 
タイムをありがとうございます。

=== prefix fix
--- input
ご自慢の御子息。
--- expected 
プライドのサン。

=== adj-basic cform fix
--- input
日本の女性は美しい。
--- expected 
ジャパンのウーマンはビューティフル。

=== original rule for exclamation and conjunction
--- input
けれども彼は宣言した。「はい。そうです。」
--- expected
But彼は宣言した。「Yes。そうです。」
--- SKIP
