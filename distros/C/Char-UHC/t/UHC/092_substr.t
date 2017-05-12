# encoding: UHC
# This file is encoded in UHC.
die "This file is not encoded in UHC.\n" if q{궇} ne "\x82\xa0";

use UHC;
print "1..20\n";

my $__FILE__ = __FILE__;

$_ = '궇궋궎궑궓궔궖궘궚궞';
if (substr($_,10) eq '궔궖궘궚궞') {
    print qq{ok - 1 substr(\$_,10) eq '궔궖궘궚궞' $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 substr(\$_,10) eq '궔궖궘궚궞' $^X $__FILE__\n};
}

$_ = '궇궋궎궑궓궔궖궘궚궞';
if (substr($_,4,6) eq '궎궑궓') {
    print qq{ok - 2 substr(\$_,4,6) eq '궎궑궓' $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 substr(\$_,4,6) eq '궎궑궓' $^X $__FILE__\n};
}

$_ = '궇궋궎궑궓궔궖궘궚궞';
if (substr($_,4,6,'궠궢궥궧궩') eq '궎궑궓') {
    if ($_ eq '궇궋궠궢궥궧궩궔궖궘궚궞') {
        print qq{ok - 3 substr(\$_,4,6,'궠궢궥궧궩') eq '궎궑궓' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 3 substr(\$_,4,6,'궠궢궥궧궩') eq '궎궑궓' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 3 substr(\$_,4,6,'궠궢궥궧궩') eq '궎궑궓' $^X $__FILE__\n};
}

$_ = '궇궋궎궑궓궔궖궘궚궞';
if (substr($_,-6) eq '궘궚궞') {
    print qq{ok - 4 substr(\$_,-6) eq '궘궚궞' $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 substr(\$_,-6) eq '궘궚궞' $^X $__FILE__\n};
}

$_ = '궇궋궎궑궓궔궖궘궚궞';
if (substr($_,-10,6) eq '궔궖궘') {
    print qq{ok - 5 substr(\$_,-10,6) eq '궔궖궘' $^X $__FILE__\n};
}
else {
    print qq{not ok - 5 substr(\$_,-10,6) eq '궔궖궘' $^X $__FILE__\n};
}

$_ = '궇궋궎궑궓궔궖궘궚궞';
if (substr($_,-10,6,'귘귚귝') eq '궔궖궘') {
    if ($_ eq '궇궋궎궑궓귘귚귝궚궞') {
        print qq{ok - 6 substr(\$_,-10,6,'귘귚귝') eq '궔궖궘' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 6 substr(\$_,-10,6,'귘귚귝') eq '궔궖궘' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 6 substr(\$_,-10,6,'귘귚귝') eq '궔궖궘' $^X $__FILE__\n};
}

$_ = '궇궋궎궑궓궔궖궘궚궞';
if (substr($_,10,0) eq '') {
    print qq{ok - 7 substr(\$_,10,0) eq '' $^X $__FILE__\n};
}
else {
    print qq{not ok - 7 substr(\$_,10,0) eq '' $^X $__FILE__\n};
}

$_ = '궇궋궎궑궓궔궖궘궚궞';
if (substr($_,10,0,'귘귚귝') eq '') {
    if ($_ eq '궇궋궎궑궓귘귚귝궔궖궘궚궞') {
        print qq{ok - 8 substr(\$_,10,0,'귘귚귝') eq '' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 8 substr(\$_,10,0,'귘귚귝') eq '' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 8 substr(\$_,10,0,'귘귚귝') eq '' $^X $__FILE__\n};
}

$_ = '궇궋궎궑궓궔궖궘궚궞';
if (substr($_,-10,0) eq '') {
    print qq{ok - 9 substr(\$_,-10,0) eq '' $^X $__FILE__\n};
}
else {
    print qq{not ok - 9 substr(\$_,-10,0) eq '' $^X $__FILE__\n};
}

$_ = '궇궋궎궑궓궔궖궘궚궞';
if (substr($_,-10,0,'귘귚귝') eq '') {
    if ($_ eq '궇궋궎궑궓귘귚귝궔궖궘궚궞') {
        print qq{ok - 10 substr(\$_,-10,0,'귘귚귝') eq '' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 10 substr(\$_,-10,0,'귘귚귝') eq '' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 10 substr(\$_,-10,0,'귘귚귝') eq '' $^X $__FILE__\n};
}

$_ = '궇궋궎궑궓궔궖궘궚궞';
if (UHC::substr($_,5) eq '궔궖궘궚궞') {
    print qq{ok - 11 UHC::substr(\$_,5) eq '궔궖궘궚궞' $^X $__FILE__\n};
}
else {
    print qq{not ok - 11 UHC::substr(\$_,5) eq '궔궖궘궚궞' $^X $__FILE__\n};
}

$_ = '궇궋궎궑궓궔궖궘궚궞';
if (UHC::substr($_,2,3) eq '궎궑궓') {
    print qq{ok - 12 UHC::substr(\$_,2,3) eq '궎궑궓' $^X $__FILE__\n};
}
else {
    print qq{not ok - 12 UHC::substr(\$_,2,3) eq '궎궑궓' $^X $__FILE__\n};
}

$_ = '궇궋궎궑궓궔궖궘궚궞';
if (UHC::substr($_,2,3,'궠궢궥궧궩') eq '궎궑궓') {
    if ($_ eq '궇궋궠궢궥궧궩궔궖궘궚궞') {
        print qq{ok - 13 UHC::substr(\$_,2,3,'궠궢궥궧궩') eq '궎궑궓' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 13 UHC::substr(\$_,2,3,'궠궢궥궧궩') eq '궎궑궓' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 13 UHC::substr(\$_,2,3,'궠궢궥궧궩') eq '궎궑궓' $^X $__FILE__\n};
}

$_ = '궇궋궎궑궓궔궖궘궚궞';
if (UHC::substr($_,-3) eq '궘궚궞') {
    print qq{ok - 14 UHC::substr(\$_,-3) eq '궘궚궞' $^X $__FILE__\n};
}
else {
    print qq{not ok - 14 UHC::substr(\$_,-3) eq '궘궚궞' $^X $__FILE__\n};
}

$_ = '궇궋궎궑궓궔궖궘궚궞';
if (UHC::substr($_,-5,3) eq '궔궖궘') {
    print qq{ok - 15 UHC::substr(\$_,-5,3) eq '궔궖궘' $^X $__FILE__\n};
}
else {
    print qq{not ok - 15 UHC::substr(\$_,-5,3) eq '궔궖궘' $^X $__FILE__\n};
}

$_ = '궇궋궎궑궓궔궖궘궚궞';
if (UHC::substr($_,-5,3,'귘귚귝') eq '궔궖궘') {
    if ($_ eq '궇궋궎궑궓귘귚귝궚궞') {
        print qq{ok - 16 UHC::substr(\$_,-5,3,'귘귚귝') eq '궔궖궘' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 16 UHC::substr(\$_,-5,3,'귘귚귝') eq '궔궖궘' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 16 UHC::substr(\$_,-5,3,'귘귚귝') eq '궔궖궘' $^X $__FILE__\n};
}

$_ = '궇궋궎궑궓궔궖궘궚궞';
if (UHC::substr($_,5,0) eq '') {
    print qq{ok - 17 UHC::substr(\$_,5,0) eq '' $^X $__FILE__\n};
}
else {
    print qq{not ok - 17 UHC::substr(\$_,5,0) eq '' $^X $__FILE__\n};
}

$_ = '궇궋궎궑궓궔궖궘궚궞';
if (UHC::substr($_,5,0,'귘귚귝') eq '') {
    if ($_ eq '궇궋궎궑궓귘귚귝궔궖궘궚궞') {
        print qq{ok - 18 UHC::substr(\$_,5,0,'귘귚귝') eq '' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 18 UHC::substr(\$_,5,0,'귘귚귝') eq '' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 18 UHC::substr(\$_,5,0,'귘귚귝') eq '' $^X $__FILE__\n};
}

$_ = '궇궋궎궑궓궔궖궘궚궞';
if (UHC::substr($_,-5,0) eq '') {
    print qq{ok - 19 UHC::substr(\$_,-5,0) eq '' $^X $__FILE__\n};
}
else {
    print qq{not ok - 19 UHC::substr(\$_,-5,0) eq '' $^X $__FILE__\n};
}

$_ = '궇궋궎궑궓궔궖궘궚궞';
if (UHC::substr($_,-5,0,'귘귚귝') eq '') {
    if ($_ eq '궇궋궎궑궓귘귚귝궔궖궘궚궞') {
        print qq{ok - 20 UHC::substr(\$_,-5,0,'귘귚귝') eq '' $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 20 UHC::substr(\$_,-5,0,'귘귚귝') eq '' $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 20 UHC::substr(\$_,-5,0,'귘귚귝') eq '' $^X $__FILE__\n};
}

__END__
