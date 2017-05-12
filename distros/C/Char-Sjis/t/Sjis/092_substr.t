# encoding: Sjis
# This file is encoded in ShiftJIS.
die "This file is not encoded in ShiftJIS.\n" if q{あ} ne "\x82\xa0";

use Sjis;
print "1..20\n";

my $__FILE__ = __FILE__;

$_ = 'あいうえおかきくけこ';
if (substr($_,10) eq 'かきくけこ') {
    print qq{ok - 1 substr(\$_,10) eq 'かきくけこ' $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 substr(\$_,10) eq 'かきくけこ' $^X $__FILE__\n};
}

$_ = 'あいうえおかきくけこ';
if (substr($_,4,6) eq 'うえお') {
    print qq{ok - 2 substr(\$_,4,6) eq 'うえお' $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 substr(\$_,4,6) eq 'うえお' $^X $__FILE__\n};
}

$_ = 'あいうえおかきくけこ';
if (substr($_,4,6,'さしすせそ') eq 'うえお') {
    if ($_ eq 'あいさしすせそかきくけこ') {
        print qq{ok - 3 substr(\$_,4,6,'さしすせそ') eq 'うえお' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 3 substr(\$_,4,6,'さしすせそ') eq 'うえお' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 3 substr(\$_,4,6,'さしすせそ') eq 'うえお' $^X $__FILE__\n};
}

$_ = 'あいうえおかきくけこ';
if (substr($_,-6) eq 'くけこ') {
    print qq{ok - 4 substr(\$_,-6) eq 'くけこ' $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 substr(\$_,-6) eq 'くけこ' $^X $__FILE__\n};
}

$_ = 'あいうえおかきくけこ';
if (substr($_,-10,6) eq 'かきく') {
    print qq{ok - 5 substr(\$_,-10,6) eq 'かきく' $^X $__FILE__\n};
}
else {
    print qq{not ok - 5 substr(\$_,-10,6) eq 'かきく' $^X $__FILE__\n};
}

$_ = 'あいうえおかきくけこ';
if (substr($_,-10,6,'やゆよ') eq 'かきく') {
    if ($_ eq 'あいうえおやゆよけこ') {
        print qq{ok - 6 substr(\$_,-10,6,'やゆよ') eq 'かきく' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 6 substr(\$_,-10,6,'やゆよ') eq 'かきく' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 6 substr(\$_,-10,6,'やゆよ') eq 'かきく' $^X $__FILE__\n};
}

$_ = 'あいうえおかきくけこ';
if (substr($_,10,0) eq '') {
    print qq{ok - 7 substr(\$_,10,0) eq '' $^X $__FILE__\n};
}
else {
    print qq{not ok - 7 substr(\$_,10,0) eq '' $^X $__FILE__\n};
}

$_ = 'あいうえおかきくけこ';
if (substr($_,10,0,'やゆよ') eq '') {
    if ($_ eq 'あいうえおやゆよかきくけこ') {
        print qq{ok - 8 substr(\$_,10,0,'やゆよ') eq '' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 8 substr(\$_,10,0,'やゆよ') eq '' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 8 substr(\$_,10,0,'やゆよ') eq '' $^X $__FILE__\n};
}

$_ = 'あいうえおかきくけこ';
if (substr($_,-10,0) eq '') {
    print qq{ok - 9 substr(\$_,-10,0) eq '' $^X $__FILE__\n};
}
else {
    print qq{not ok - 9 substr(\$_,-10,0) eq '' $^X $__FILE__\n};
}

$_ = 'あいうえおかきくけこ';
if (substr($_,-10,0,'やゆよ') eq '') {
    if ($_ eq 'あいうえおやゆよかきくけこ') {
        print qq{ok - 10 substr(\$_,-10,0,'やゆよ') eq '' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 10 substr(\$_,-10,0,'やゆよ') eq '' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 10 substr(\$_,-10,0,'やゆよ') eq '' $^X $__FILE__\n};
}

$_ = 'あいうえおかきくけこ';
if (Sjis::substr($_,5) eq 'かきくけこ') {
    print qq{ok - 11 Sjis::substr(\$_,5) eq 'かきくけこ' $^X $__FILE__\n};
}
else {
    print qq{not ok - 11 Sjis::substr(\$_,5) eq 'かきくけこ' $^X $__FILE__\n};
}

$_ = 'あいうえおかきくけこ';
if (Sjis::substr($_,2,3) eq 'うえお') {
    print qq{ok - 12 Sjis::substr(\$_,2,3) eq 'うえお' $^X $__FILE__\n};
}
else {
    print qq{not ok - 12 Sjis::substr(\$_,2,3) eq 'うえお' $^X $__FILE__\n};
}

$_ = 'あいうえおかきくけこ';
if (Sjis::substr($_,2,3,'さしすせそ') eq 'うえお') {
    if ($_ eq 'あいさしすせそかきくけこ') {
        print qq{ok - 13 Sjis::substr(\$_,2,3,'さしすせそ') eq 'うえお' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 13 Sjis::substr(\$_,2,3,'さしすせそ') eq 'うえお' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 13 Sjis::substr(\$_,2,3,'さしすせそ') eq 'うえお' $^X $__FILE__\n};
}

$_ = 'あいうえおかきくけこ';
if (Sjis::substr($_,-3) eq 'くけこ') {
    print qq{ok - 14 Sjis::substr(\$_,-3) eq 'くけこ' $^X $__FILE__\n};
}
else {
    print qq{not ok - 14 Sjis::substr(\$_,-3) eq 'くけこ' $^X $__FILE__\n};
}

$_ = 'あいうえおかきくけこ';
if (Sjis::substr($_,-5,3) eq 'かきく') {
    print qq{ok - 15 Sjis::substr(\$_,-5,3) eq 'かきく' $^X $__FILE__\n};
}
else {
    print qq{not ok - 15 Sjis::substr(\$_,-5,3) eq 'かきく' $^X $__FILE__\n};
}

$_ = 'あいうえおかきくけこ';
if (Sjis::substr($_,-5,3,'やゆよ') eq 'かきく') {
    if ($_ eq 'あいうえおやゆよけこ') {
        print qq{ok - 16 Sjis::substr(\$_,-5,3,'やゆよ') eq 'かきく' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 16 Sjis::substr(\$_,-5,3,'やゆよ') eq 'かきく' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 16 Sjis::substr(\$_,-5,3,'やゆよ') eq 'かきく' $^X $__FILE__\n};
}

$_ = 'あいうえおかきくけこ';
if (Sjis::substr($_,5,0) eq '') {
    print qq{ok - 17 Sjis::substr(\$_,5,0) eq '' $^X $__FILE__\n};
}
else {
    print qq{not ok - 17 Sjis::substr(\$_,5,0) eq '' $^X $__FILE__\n};
}

$_ = 'あいうえおかきくけこ';
if (Sjis::substr($_,5,0,'やゆよ') eq '') {
    if ($_ eq 'あいうえおやゆよかきくけこ') {
        print qq{ok - 18 Sjis::substr(\$_,5,0,'やゆよ') eq '' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 18 Sjis::substr(\$_,5,0,'やゆよ') eq '' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 18 Sjis::substr(\$_,5,0,'やゆよ') eq '' $^X $__FILE__\n};
}

$_ = 'あいうえおかきくけこ';
if (Sjis::substr($_,-5,0) eq '') {
    print qq{ok - 19 Sjis::substr(\$_,-5,0) eq '' $^X $__FILE__\n};
}
else {
    print qq{not ok - 19 Sjis::substr(\$_,-5,0) eq '' $^X $__FILE__\n};
}

$_ = 'あいうえおかきくけこ';
if (Sjis::substr($_,-5,0,'やゆよ') eq '') {
    if ($_ eq 'あいうえおやゆよかきくけこ') {
        print qq{ok - 20 Sjis::substr(\$_,-5,0,'やゆよ') eq '' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 20 Sjis::substr(\$_,-5,0,'やゆよ') eq '' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 20 Sjis::substr(\$_,-5,0,'やゆよ') eq '' $^X $__FILE__\n};
}

__END__
