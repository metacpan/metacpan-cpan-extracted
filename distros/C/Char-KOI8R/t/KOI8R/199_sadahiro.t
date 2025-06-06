# encoding: KOI8R
# This file is encoded in KOI8-R.
die "This file is not encoded in KOI8-R.\n" if q{あ} ne "\x82\xa0";

use KOI8R;
print "1..1\n";

my $__FILE__ = __FILE__;

# 後読み言明 (例えば C<(?<=[A-Z])>) が直前の二バイト文字の第二バイトに
# 誤ってマッチすることには対処されていません。
# 例えば、 C<match("アイウ", '(?<=[A-Z])(\p{Kana})')> は C<('イ')>
# を返しますが、もちろん誤りです。

if ('アイウ' =~ /(?<=[A-Z])([アイウ])/) {
    print "ok - 1 $^X $__FILE__ ('アイウ' =~ /(?<=[A-Z])([アイウ])/)($1)\n";
}
else {
    print "not ok - 1 $^X $__FILE__ ('アイウ' =~ /(?<=[A-Z])([アイウ])/)()\n";
}

__END__

