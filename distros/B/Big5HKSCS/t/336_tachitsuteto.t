# encoding: Big5HKSCS
# This file is encoded in Big5-HKSCS.
die "This file is not encoded in Big5-HKSCS.\n" if q{あ} ne "\x82\xa0";

use Big5HKSCS;
print "1..10\n";

my $__FILE__ = __FILE__;

$line   = "A^チツテト";
$before = "A^";
$after  = "BB";

# マッチしないのが正しい
if ($line !~ s/$before/$after/) {
    if ($line eq "A^チツテト") {
        print qq{ok - 1 \$line !~ s/\$before/\$after/ --> ($line) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 1 \$line !~ s/\$before/\$after/ --> ($line) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 1 \$line !~ s/\$before/\$after/ --> ($line) $^X $__FILE__\n};
}

$line   = "A^チツテト";
$before = "A^";
$after  = "BB";

# マッチさせるためには \Q...\E が必要
if ($line =~ s/\Q$before\E/$after/) {
    if ($line eq "BBチツテト") {
        print qq{ok - 2 \$line =~ s/\\Q\$before\\E/\$after/ --> ($line) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 2 \$line =~ s/\\Q\$before\\E/\$after/ --> ($line) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 2 \$line =~ s/\\Q\$before\\E/\$after/ --> ($line) $^X $__FILE__\n};
}

$line   = "タチツテト";
$before = "タ";
$after  = "た";

# この記述で JPerl の場合はマッチし、Perl の場合はマッチしない
# Perl 互換か JPerl 互換のどちらにするか悩んだが...
# Perl 互換ということでマッチしないのが正しいということにした
if ($line !~ s/$before/$after/) {
    if ($line eq "タチツテト") {
        print qq{ok - 3 \$line !~ s/\$before/\$after/ --> ($line) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 3 \$line !~ s/\$before/\$after/ --> ($line) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 3 \$line !~ s/\$before/\$after/ --> ($line) $^X $__FILE__\n};
}

$line   = "タチツテト";
$before = "タ";
$after  = "た";

# マッチさせるためには Perl の場合のように \Q...\E が必要
if ($line =~ s/\Q$before\E/$after/) {
    if ($line eq "たチツテト") {
        print qq{ok - 4 \$line =~ s/\\Q\$before\\E/\$after/ --> ($line) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 4 \$line =~ s/\\Q\$before\\E/\$after/ --> ($line) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 4 \$line =~ s/\\Q\$before\\E/\$after/ --> ($line) $^X $__FILE__\n};
}

$line = "あああああ";
$ret = $line =~ s/タ/た/g;

if (not $ret) {
    if ($line eq "あああああ") {
        print qq{ok - 5 "あああああ" =~ s/タ/た/ --> ($ret)($line) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 5 "あああああ" =~ s/タ/た/ --> ($ret)($line) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 5 "あああああ" =~ s/タ/た/ --> ($ret)($line) $^X $__FILE__\n};
}

$line = "タああああ";
$ret = $line =~ s/タ/た/g;

if ($ret == 1) {
    if ($line eq "たああああ") {
        print qq{ok - 6 "タああああ" =~ s/タ/た/ --> ($ret)($line) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 6 "タああああ" =~ s/タ/た/ --> ($ret)($line) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 6 "タああああ" =~ s/タ/た/ --> ($ret)($line) $^X $__FILE__\n};
}

$line = "タあタあタ";
$ret = $line =~ s/タ/た/g;

if ($ret == 3) {
    if ($line eq "たあたあた") {
        print qq{ok - 7 "タあタあタ" =~ s/タ/た/ --> ($ret)($line) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 7 "タあタあタ" =~ s/タ/た/ --> ($ret)($line) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 7 "タあタあタ" =~ s/タ/た/ --> ($ret)($line) $^X $__FILE__\n};
}

$line = "あああああ";
$ret = $line !~ s/タ/た/g;

if ($ret == 1) {
    if ($line eq "あああああ") {
        print qq{ok - 8 "あああああ" !~ s/タ/た/ --> ($ret)($line) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 8 "あああああ" !~ s/タ/た/ --> ($ret)($line) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 8 "あああああ" !~ s/タ/た/ --> ($ret)($line) $^X $__FILE__\n};
}

$line = "タああああ";
$ret = $line !~ s/タ/た/g;

if (not $ret) {
    if ($line eq "たああああ") {
        print qq{ok - 9 "タああああ" !~ s/タ/た/ --> ($ret)($line) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 9 "タああああ" !~ s/タ/た/ --> ($ret)($line) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 9 "タああああ" !~ s/タ/た/ --> ($ret)($line) $^X $__FILE__\n};
}

$line = "タあタあタ";
$ret = $line !~ s/タ/た/g;

if (not $ret) {
    if ($line eq "たあたあた") {
        print qq{ok - 10 "タあタあタ" !~ s/タ/た/ --> ($ret)($line) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 10 "タあタあタ" !~ s/タ/た/ --> ($ret)($line) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 10 "タあタあタ" !~ s/タ/た/ --> ($ret)($line) $^X $__FILE__\n};
}

__END__

人力検索はてな > ウェブ制作 > perlで「タ」の置換ができないので、対処方法教えてください。
http://q.hatena.ne.jp/1222486577

samasuya さんの質問

perlで「タ」の置換ができないので、対処方法教えてください。
 
WindowsXPにインストールしたperl, v5.8.7で、「タ」の置換を行いたいのですが、
なぜかできません。その他の文字はできます。

ソースですが、

$line   = "タチツテト";
$before = "タ";
$after  = "た";
$line =~ s/$before/$after/;
print $line;

です。

ソースは、SJISで書いてます。
よろしくお願いします
