# encoding: GB18030
# This file is encoded in GB18030.
die "This file is not encoded in GB18030.\n" if q{偁} ne "\x82\xa0";

use GB18030;
print "1..16\n";

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
        for my $tno (1..16) {
            print "ok - $tno # SKIP $^X $0\n";
        }
        exit;
    }
}
else {
    for my $tno (1..16) {
        print "ok - $tno # SKIP $^X $0\n";
    }
    exit;
}

# 寈崘傪昞帵偟側偄傛偆偵偡傞
$^W = 0;

# 32,766 傪挻偊傞抣傪愝掕偡傞
my $over15bit = 33000;

my $str = '';

# 懳徾偼1,2僶僀僩暥帤楍: 堦夞偩偗儅僢僠偡傞
$str = ('偁1' x $over15bit) . '傾僀ABC';
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

# 懳徾偼1,2僶僀僩暥帤楍: 堦夞偩偗儅僢僠偟側偄
$str = ('偁1' x $over15bit) . '傾abc';
if ($str =~ /([A-Z]+)/o) {
    print "not ok - 2 $^X $__FILE__ ($1)\n";
}
else {
    print "ok - 2 $^X $__FILE__\n";
}

# 懳徾偼1,2僶僀僩暥帤楍: 僌儘乕僶儖儅僢僠偡傞
$str = '偁1' x $over15bit . '傾僀ABC'. '偍2' x $over15bit . '僂僄XYZ';
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

# 懳徾偼1,2僶僀僩暥帤楍: 僌儘乕僶儖儅僢僠偟側偄
$str = '偁1' x $over15bit . '傾僀abc'. '偍2' x $over15bit . '僂僄xyz';
if (my @array = $str =~ /([A-Z]+)/go) {
    print "not ok - 4 $^X $__FILE__ (@array)\n";
}
else {
    print "ok - 4 $^X $__FILE__\n";
}

# 懳徾偼1,4僶僀僩暥帤楍: 堦夞偩偗儅僢僠偡傞
$str = ('񸆀1' x $over15bit) . '傾僀ABC';
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

# 懳徾偼1,4僶僀僩暥帤楍: 堦夞偩偗儅僢僠偟側偄
$str = ('񸆀1' x $over15bit) . '傾abc';
if ($str =~ /([A-Z]+)/o) {
    print "not ok - 6 $^X $__FILE__ ($1)\n";
}
else {
    print "ok - 6 $^X $__FILE__\n";
}

# 懳徾偼1,4僶僀僩暥帤楍: 僌儘乕僶儖儅僢僠偡傞
$str = '񸆀1' x $over15bit . '傾僀ABC'. '偍2' x $over15bit . '僂僄XYZ';
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

# 懳徾偼1,4僶僀僩暥帤楍: 僌儘乕僶儖儅僢僠偟側偄
$str = '񸆀1' x $over15bit . '傾僀abc'. '偍2' x $over15bit . '僂僄xyz';
if (my @array = $str =~ /([A-Z]+)/go) {
    print "not ok - 8 $^X $__FILE__ (@array)\n";
}
else {
    print "ok - 8 $^X $__FILE__\n";
}

# 懳徾偼1,2,4僶僀僩暥帤楍: 堦夞偩偗儅僢僠偡傞
$str = ('񸆀偁1' x $over15bit) . '傾僀ABC';
if ($str =~ /([A-Z]+)/o) {
    if ($1 eq 'ABC') {
        print "ok - 9 $^X $__FILE__\n";
    }
    else {
        print "not ok - 9 $^X $__FILE__\n";
    }
}
else {
    print "not ok - 9 $^X $__FILE__\n";
}

# 懳徾偼1,2,4僶僀僩暥帤楍: 堦夞偩偗儅僢僠偟側偄
$str = ('񸆀偁1' x $over15bit) . '傾abc';
if ($str =~ /([A-Z]+)/o) {
    print "not ok - 10 $^X $__FILE__ ($1)\n";
}
else {
    print "ok - 10 $^X $__FILE__\n";
}

# 懳徾偼1,2,4僶僀僩暥帤楍: 僌儘乕僶儖儅僢僠偡傞
$str = '񸆀偁1' x $over15bit . '傾僀ABC'. '偍2' x $over15bit . '僂僄XYZ';
if (my @array = $str =~ /([A-Z]+)/go) {
    if (join(' ',@array) eq 'ABC XYZ') {
        print "ok - 11 $^X $__FILE__\n";
    }
    else {
        print "not ok - 11 $^X $__FILE__\n";
    }
}
else {
    print "not ok - 11 $^X $__FILE__\n";
}

# 懳徾偼1,2,4僶僀僩暥帤楍: 僌儘乕僶儖儅僢僠偟側偄
$str = '񸆀偁1' x $over15bit . '傾僀abc'. '偍2' x $over15bit . '僂僄xyz';
if (my @array = $str =~ /([A-Z]+)/go) {
    print "not ok - 12 $^X $__FILE__ (@array)\n";
}
else {
    print "ok - 12 $^X $__FILE__\n";
}

# 懳徾偼僔儞僌儖僶僀僩暥帤楍: 堦夞偩偗儅僢僠偡傞
$str = ('a1' x $over15bit) . 'ABC';
if ($str =~ /([A-Z]+)/o) {
    if ($1 eq 'ABC') {
        print "ok - 13 $^X $__FILE__\n";
    }
    else {
        print "not ok - 13 $^X $__FILE__\n";
    }
}
else {
    print "not ok - 13 $^X $__FILE__\n";
}

# 懳徾偼僔儞僌儖僶僀僩暥帤楍: 堦夞偩偗儅僢僠偟側偄
$str = ('a1' x $over15bit) . 'abc';
if ($str =~ /([A-Z]+)/o) {
    print "not ok - 14 $^X $__FILE__\n";
}
else {
    print "ok - 14 $^X $__FILE__\n";
}

# 懳徾偼僔儞僌儖僶僀僩暥帤楍: 僌儘乕僶儖儅僢僠偡傞
$str = 'a1' x $over15bit . 'ABC'. 'b2' x $over15bit . 'XYZ';
if (my @array = $str =~ /([A-Z]+)/go) {
    if (join(' ',@array) eq 'ABC XYZ') {
        print "ok - 15 $^X $__FILE__\n";
    }
    else {
        print "not ok - 15 $^X $__FILE__\n";
    }
}
else {
    print "not ok - 15 $^X $__FILE__\n";
}

# 懳徾偼僔儞僌儖僶僀僩暥帤楍: 僌儘乕僶儖儅僢僠偟側偄
$str = 'a1' x $over15bit . 'abc'. 'b2' x $over15bit . 'xyz';
if (my @array = $str =~ /([A-Z]+)/go) {
    print "not ok - 16 $^X $__FILE__\n";
}
else {
    print "ok - 16 $^X $__FILE__\n";
}

__END__
Shift-JIS僥僉僗僩傪惓偟偔埖偆
挿偄暥帤楍偵懳偡傞惓婯昞尰専嶕
http://homepage1.nifty.com/nomenclator/perl/shiftjis.htm
