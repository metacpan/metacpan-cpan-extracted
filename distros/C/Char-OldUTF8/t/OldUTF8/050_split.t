# encoding: OldUTF8
# This file is encoded in old UTF-8.
die "This file is not encoded in old UTF-8.\n" if q{あ} ne "\xe3\x81\x82";

use OldUTF8;
print "1..15\n";

my $__FILE__ = __FILE__;

$text = 'ＩＯ．ＳＹＳ：２２５５５８：９５－１０－０３：－ａ－ｓｈ：ｏｐｔｉｏｎａｌ';

# 7.7 split演算子(リストコンテキスト)
@_ = split(/：/, $text);
if (join('', map {"($_)"} @_) eq "(ＩＯ．ＳＹＳ)(２２５５５８)(９５－１０－０３)(－ａ－ｓｈ)(ｏｐｔｉｏｎａｌ)") {
    print qq{ok - 1 \@_ = split(/：/, \$text); $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 \@_ = split(/：/, \$text); $^X $__FILE__\n};
}

# 特殊なマッチ被演算子 // を使った場合
@_ = split(//, "ｓｈｏｒｔ　ｔｅｓｔ");
if (join('', map {"($_)"} @_) eq "(ｓ)(ｈ)(ｏ)(ｒ)(ｔ)(　)(ｔ)(ｅ)(ｓ)(ｔ)") {
    print qq{ok - 2 \@_ = split(//, "ｓｈｏｒｔ　ｔｅｓｔ") $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 \@_ = split(//, "ｓｈｏｒｔ　ｔｅｓｔ") $^X $__FILE__\n};
}

# 特殊なマッチ被演算子 " "(スペース1個分の通常の文字列)を使った場合
@_ = split(" ", "   ａ ｓｈｏｒｔ   ｔｅｓｔ   ");
if (join('', map {"($_)"} @_) eq "(ａ)(ｓｈｏｒｔ)(ｔｅｓｔ)") {
    print qq{ok - 3 \@_ = split(" ", "   ａ ｓｈｏｒｔ   ｔｅｓｔ   ") $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 \@_ = split(" ", "   ａ ｓｈｏｒｔ   ｔｅｓｔ   ") $^X $__FILE__\n};
}

# 先頭の空白を残したい場合
@_ = split(m/\s+/, "   ａ ｓｈｏｒｔ   ｔｅｓｔ   ");
if (join('', map {"($_)"} @_) eq "()(ａ)(ｓｈｏｒｔ)(ｔｅｓｔ)") {
    print qq{ok - 4 \@_ = split(m/\\s+/, "   ａ ｓｈｏｒｔ   ｔｅｓｔ   ") $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 \@_ = split(m/\\s+/, "   ａ ｓｈｏｒｔ   ｔｅｓｔ   ") $^X $__FILE__\n};
}

# 末尾の空白を残したい場合
@_ = split(" ", "   ａ ｓｈｏｒｔ   ｔｅｓｔ   ", -1);
if (join('', map {"($_)"} @_) eq "(ａ)(ｓｈｏｒｔ)(ｔｅｓｔ)()") {
    print qq{ok - 5 \@_ = split(" ", "   ａ ｓｈｏｒｔ   ｔｅｓｔ   ", -1) $^X $__FILE__\n};
}
else {
    print qq{not ok - 5 \@_ = split(" ", "   ａ ｓｈｏｒｔ   ｔｅｓｔ   ", -1) $^X $__FILE__\n};
}

# マッチ被演算子が指定されていない場合
$_ = "   ａ ｓｈｏｒｔ   ｔｅｓｔ   ";
@_ = split;
if (join('', map {"($_)"} @_) eq "(ａ)(ｓｈｏｒｔ)(ｔｅｓｔ)") {
    print qq{ok - 6 \@_ = split $^X $__FILE__\n};
}
else {
    print qq{not ok - 6 \@_ = split $^X $__FILE__\n};
}

# 7.7.1.2 ターゲット文字列が指定されていない場合
$_ = $text;
@_ = split(/：/);
if (join('', map {"($_)"} @_) eq "(ＩＯ．ＳＹＳ)(２２５５５８)(９５－１０－０３)(－ａ－ｓｈ)(ｏｐｔｉｏｎａｌ)") {
    print qq{ok - 7 \@_ = split(/：/) $^X $__FILE__\n};
}
else {
    print qq{not ok - 7 \@_ = split(/：/) $^X $__FILE__\n};
}

# 7.7.1.3 個数上限被演算子の基本
@_ = split(/：/, $text, 3);
if (join('', map {"($_)"} @_) eq "(ＩＯ．ＳＹＳ)(２２５５５８)(９５－１０－０３：－ａ－ｓｈ：ｏｐｔｉｏｎａｌ)") {
    print qq{ok - 8 \@_ = split(/：/, \$text, 3) $^X $__FILE__\n};
}
else {
    print qq{not ok - 8 \@_ = split(/：/, \$text, 3) $^X $__FILE__\n};
}

# 7.7.2 空要素
@_ = split(m/：/, "１２：３４：：７８");
if (join('', map {"($_)"} @_) eq "(１２)(３４)()(７８)") {
    print qq{ok - 9 \@_ = split(m/：/, "１２：３４：：７８") $^X $__FILE__\n};
}
else {
    print qq{not ok - 9 \@_ = split(m/：/, "１２：３４：：７８") $^X $__FILE__\n};
}

# 7.7.2.1 末尾の空要素
@_ = split(m/：/, "１２：３４：：７８：：：");
if (join('', map {"($_)"} @_) eq "(１２)(３４)()(７８)") {
    print qq{ok - 10 \@_ = split(m/：/, "１２：３４：：７８：：：") $^X $__FILE__\n};
}
else {
    print qq{not ok - 10 \@_ = split(m/：/, "１２：３４：：７８：：：") $^X $__FILE__\n};
}

# 7.7.2.3 文字列の両端での特殊なマッチ
@_ = split(m/：/, "：１２：３４：：７８");
if (join('', map {"($_)"} @_) eq "()(１２)(３４)()(７８)") {
    print qq{ok - 11 \@_ = split(m/：/, "：１２：３４：：７８") $^X $__FILE__\n};
}
else {
    print qq{not ok - 11 \@_ = split(m/：/, "：１２：３４：：７８") $^X $__FILE__\n};
}

# 「^」という正規表現を使った場合
$_ = "ＡＡＡ\nＢＢＢ\nＣＣＣ";
@_ = split(m/^/, $_);
if (join('', map {"($_)"} @_) eq "(ＡＡＡ\n)(ＢＢＢ\n)(ＣＣＣ)") {
    print qq{ok - 12 \@_ = split(m/^/, \$\_) $^X $__FILE__\n};
}
else {
    print qq{not ok - 12 \@_ = split(m/^/, \$\_) $^X $__FILE__\n};
}
@_ = split(m/^/m, $_);
if (join('', map {"($_)"} @_) eq "(ＡＡＡ\n)(ＢＢＢ\n)(ＣＣＣ)") {
    print qq{ok - 13 \@_ = split(m/^/m, \$\_) $^X $__FILE__\n};
}
else {
    print qq{not ok - 13 \@_ = split(m/^/m, \$\_) $^X $__FILE__\n};
}

# 7.7.4 キャプチャ付き括弧を含む split のマッチ被演算子
@_ = split(/(<[^>]*>)/, "　ａｎｄ　<Ｂ>ｖｅｒｙ　<ＦＯＮＴ　ｃｏｌｏｒ＝ｒｅｄ>ｖｅｒｙ</ＦＯＮＴ>　ｍｕｃｈ</B>　ｅｆｆｏｒｔ");
if (join('', map {"($_)"} @_) eq "(　ａｎｄ　)(<Ｂ>)(ｖｅｒｙ　)(<ＦＯＮＴ　ｃｏｌｏｒ＝ｒｅｄ>)(ｖｅｒｙ)(</ＦＯＮＴ>)(　ｍｕｃｈ)(</B>)(　ｅｆｆｏｒｔ)") {
    print qq{ok - 14 \@_ = split(/(<[^>]*>)/, "　ａｎｄ　<Ｂ>ｖｅｒｙ　<ＦＯＮＴ　ｃｏｌｏｒ＝ｒｅｄ>ｖｅｒｙ</ＦＯＮＴ>　ｍｕｃｈ</B>　ｅｆｆｏｒｔ") $^X $__FILE__\n};
}
else {
    print qq{not ok - 14 \@_ = split(/(<[^>]*>)/, "　ａｎｄ　<Ｂ>ｖｅｒｙ　<ＦＯＮＴ　ｃｏｌｏｒ＝ｒｅｄ>ｖｅｒｙ</ＦＯＮＴ>　ｍｕｃｈ</B>　ｅｆｆｏｒｔ") $^X $__FILE__\n};
}

# 7.7.3.1 split には副作用がないことの確認
$a = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
$a =~ m/ABC(DEF)G(HI)/;
if (($1 eq "DEF") and ($2 eq "HI")) {
    $b = "123,45,6,78,,90";
    @_ = split(/,/,$b);
    if (($1 eq "DEF") and ($2 eq "HI")) {
        print qq{ok - 15 split に副作用がないことの確認 ($1)($2) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 15 split に副作用がないことの確認 ($1)($2) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 15 split に副作用がないことの確認 ($1)($2) $^X $__FILE__\n};
}

__END__
