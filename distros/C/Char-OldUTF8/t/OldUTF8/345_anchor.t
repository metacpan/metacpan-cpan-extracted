# encoding: OldUTF8
# This file is encoded in old UTF-8.
die "This file is not encoded in old UTF-8.\n" if q{あ} ne "\xe3\x81\x82";

use OldUTF8;
print "1..8\n";

my $__FILE__ = __FILE__;

my $anchor1 = q{\G(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x00-\xFF])*?};
my $anchor2 = q{\G(?(?!.{32766})(?:[\x81-\x9F\xE0-\xFC][\x00-\xFF]|[\x00-\xFF])*?|(?(?=[\x00-\x7F]+\z).*?|.*?[^\x81-\x9F\xE0-\xFC](?:[\x81-\x9F\xE0-\xFC][\x00-\xFF])*?))};

if (($] >= 5.010001) or
    (($] >= 5.008) and ($^O eq 'MSWin32') and (defined($ActivePerl::VERSION) and ($ActivePerl::VERSION > 800))) or
    (($] =~ /\A 5\.006/oxms) and ($^O eq 'MSWin32'))
) {
    # avoid: Complex regular subexpression recursion limit (32766) exceeded at here.
    local $^W = 0;

    if (((('A' x 32768).'B') !~ /${anchor1}B/b) and
        ((('A' x 32768).'B') =~ /${anchor2}B/b)
    ) {
        # do test
    }
    else {
        for my $tno (1..8) {
            print "ok - $tno # SKIP $^X $0\n";
        }
        exit;
    }
}
else {
    for my $tno (1..8) {
        print "ok - $tno # SKIP $^X $0\n";
    }
    exit;
}

# 32,766 を超える値を設定する
my $over15bit = 33000;

my $str = '';

# 対象はマルチバイト文字列: 一回だけマッチする
$str = ('あ1' x $over15bit) . 'アイABC';
if ($str =~ /([A-Z]+)/o) {
    if ($1 eq 'ABC') {
        print "ok - 1 $^X $__FILE__\n";
    }
    else {
        print "not ok - 1 $^X $__FILE__\n";
    }
}
else {
    print "not ok - 1 $^X $__FILE__\n";
}

# 対象はマルチバイト文字列: 一回だけマッチしない
$str = ('あ1' x $over15bit) . 'アabc';
if ($str =~ /([A-Z]+)/o) {
    print "not ok - 2 $^X $__FILE__ ($1)\n";
}
else {
    print "ok - 2 $^X $__FILE__\n";
}

# 対象はマルチバイト文字列: グローバルマッチする
$str = 'あ1' x $over15bit . 'アイABC'. 'お2' x $over15bit . 'ウエXYZ';
if (my @array = $str =~ /([A-Z]+)/go) {
    if (join(' ',@array) eq 'ABC XYZ') {
        print "ok - 3 $^X $__FILE__\n";
    }
    else {
        print "not ok - 3 $^X $__FILE__\n";
    }
}
else {
    print "not ok - 3 $^X $__FILE__\n";
}

# 対象はマルチバイト文字列: グローバルマッチしない
$str = 'あ1' x $over15bit . 'アイabc'. 'お2' x $over15bit . 'ウエxyz';
if (my @array = $str =~ /([A-Z]+)/go) {
    print "not ok - 4 $^X $__FILE__ (@array)\n";
}
else {
    print "ok - 4 $^X $__FILE__\n";
}

# 対象はシングルバイト文字列: 一回だけマッチする
$str = ('a1' x $over15bit) . 'ABC';
if ($str =~ /([A-Z]+)/o) {
    if ($1 eq 'ABC') {
        print "ok - 5 $^X $__FILE__\n";
    }
    else {
        print "not ok - 5 $^X $__FILE__\n";
    }
}
else {
    print "not ok - 5 $^X $__FILE__\n";
}

# 対象はシングルバイト文字列: 一回だけマッチしない
$str = ('a1' x $over15bit) . 'abc';
if ($str =~ /([A-Z]+)/o) {
    print "not ok - 6 $^X $__FILE__\n";
}
else {
    print "ok - 6 $^X $__FILE__\n";
}

# 対象はシングルバイト文字列: グローバルマッチする
$str = 'a1' x $over15bit . 'ABC'. 'b2' x $over15bit . 'XYZ';
if (my @array = $str =~ /([A-Z]+)/go) {
    if (join(' ',@array) eq 'ABC XYZ') {
        print "ok - 7 $^X $__FILE__\n";
    }
    else {
        print "not ok - 7 $^X $__FILE__\n";
    }
}
else {
    print "not ok - 7 $^X $__FILE__\n";
}

# 対象はシングルバイト文字列: グローバルマッチしない
$str = 'a1' x $over15bit . 'abc'. 'b2' x $over15bit . 'xyz';
if (my @array = $str =~ /([A-Z]+)/go) {
    print "not ok - 8 $^X $__FILE__\n";
}
else {
    print "ok - 8 $^X $__FILE__\n";
}

__END__
Shift-JISテキストを正しく扱う
長い文字列に対する正規表現検索
http://homepage1.nifty.com/nomenclator/perl/shiftjis.htm
