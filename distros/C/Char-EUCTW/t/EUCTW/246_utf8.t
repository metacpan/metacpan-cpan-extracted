# encoding: EUCTW
# This file is encoded in EUC-TW.
die "This file is not encoded in EUC-TW.\n" if q{あ} ne "\xa4\xa2";

# 関数 utf8::* のテスト

my $__FILE__ = __FILE__;

use EUCTW;
print "1..12\n";

use utf8;

# utf8::upgrade()

my $var1 = 'あいうえお';
my $var2 = 'あいうえお';
eval { utf8::upgrade($var1); };
if (not $@) {
    print "ok - 1 eval { utf8::upgrade(\$var1); } $^X $__FILE__\n";
    if (utf8::upgrade($var2) == length($var2)) {
        print "ok - 2 utf8::upgrade(\$var2) == length(\$var2) $^X $__FILE__\n";
    }
    else {
        print "not ok - 2 utf8::upgrade(\$var2) == length(\$var2) $^X $__FILE__\n";
    }
}
else {
    print "not ok - 1 eval { utf8::upgrade(\$var1); } $^X $__FILE__\n";
    print "not ok - 2 utf8::upgrade(\$var2) == length(\$var2) $^X $__FILE__\n";
}

# utf8::downgrade()

eval { utf8::downgrade($var1); };
if (not $@) {
    print "ok - 3 eval { utf8::downgrade(\$var1); } $^X $__FILE__\n";
    if (utf8::downgrade($var2) == 1) {
        print "ok - 4 utf8::downgrade(\$var2) == 1 $^X $__FILE__\n";
    }
    else {
        print "not ok - 4 utf8::downgrade(\$var2) == 1 $^X $__FILE__\n";
    }
}
else {
    print "not ok - 3 eval { utf8::downgrade(\$var1); } $^X $__FILE__\n";
    print "not ok - 4 utf8::downgrade(\$var2) == 1 $^X $__FILE__\n";
}

# utf8::decode()

my $var3 = 'あいうえお';
my $var4 = 'あいうえお';
eval { utf8::decode($var3); };
if (not $@) {
    print "ok - 5 eval { utf8::decode(\$var3); } $^X $__FILE__\n";
    if (utf8::decode($var4) == 1) {
        print "ok - 6 utf8::decode(\$var4) == 1 $^X $__FILE__\n";
    }
    else {
        print "not ok - 6 utf8::decode(\$var4) == 1 $^X $__FILE__\n";
    }
}
else {
    print "not ok - 5 eval { utf8::decode(\$var3); } $^X $__FILE__\n";
    print "not ok - 6 utf8::decode(\$var4) == 1 $^X $__FILE__\n";
}

# utf8::encode()

eval { utf8::encode($var3); };
if (not $@) {
    print "ok - 7 eval { utf8::encode(\$var3); } $^X $__FILE__\n";
    if (not defined utf8::encode($var4)) {
        print "ok - 8 not defined utf8::encode(\$var4) $^X $__FILE__\n";
    }
    else {
        print "not ok - 8 not defined utf8::encode(\$var4) $^X $__FILE__\n";
    }
}
else {
    print "not ok - 7 eval { utf8::encode(\$var3); } $^X $__FILE__\n";
    print "not ok - 8 not defined utf8::encode(\$var4) $^X $__FILE__\n";
}

# utf8::is_utf8()

eval { utf8::is_utf8($var3); };
if (not $@) {
    print "ok - 9 eval { utf8::is_utf8(\$var3); } $^X $__FILE__\n";
    if (not defined utf8::is_utf8($var3)) {
        print "ok - 10 not defined utf8::is_utf8(\$var3) $^X $__FILE__\n";
    }
    else {
        print "not ok - 10 not defined utf8::is_utf8(\$var3) $^X $__FILE__\n";
    }
}
else {
    print "not ok - 9 eval { utf8::is_utf8(\$var3); } $^X $__FILE__\n";
    print "not ok - 10 not defined utf8::is_utf8(\$var3) $^X $__FILE__\n";
}

# utf8::valid()

eval { utf8::valid($var3); };
if (not $@) {
    print "ok - 11 eval { utf8::valid(\$var3); } $^X $__FILE__\n";
    if (utf8::valid($var3) == 1) {
        print "ok - 12 utf8::valid(\$var3) == 1 $^X $__FILE__\n";
    }
    else {
        print "not ok - 12 utf8::valid(\$var3) == 1 $^X $__FILE__\n";
    }
}
else {
    print "not ok - 11 eval { utf8::valid(\$var3); } $^X $__FILE__\n";
    print "not ok - 12 utf8::valid(\$var3) == 1 $^X $__FILE__\n";
}

__END__

