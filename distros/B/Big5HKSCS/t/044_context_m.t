# encoding: Big5HKSCS
# This file is encoded in Big5-HKSCS.
die "This file is not encoded in Big5-HKSCS.\n" if q{あ} ne "\x82\xa0";

use Big5HKSCS;
print "1..8\n";

my $__FILE__ = __FILE__;

# /g なしのスカラーコンテキスト
$success = "アソア" =~ /ソ/;
if ($success) {
    print qq{ok - 1 "アソア" =~ /ソ/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 "アソア" =~ /ソ/ $^X $__FILE__\n};
}

# /g なしのリストコンテキスト
if (($c1,$c2,$c3,$c4) = "サシスセソタチツテト" =~ /^...(.)(.)(.)(.)...$/) {
    if ("($c1)($c2)($c3)($c4)" eq "(セ)(ソ)(タ)(チ)") {
        print qq{ok - 2 "サシスセソタチツテト" =~ /^...(.)(.)(.)(.)...\$/ $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 2 "サシスセソタチツテト" =~ /^...(.)(.)(.)(.)...\$/ ($c1)($c2)($c3)($c4) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 2 "サシスセソタチツテト" =~ /^...(.)(.)(.)(.)...\$/ ($c1)($c2)($c3)($c4) $^X $__FILE__\n};
}

# /g ありのリストコンテキスト
@c = "サシスセソタチツテト" =~ /./g;
if (@c) {
    $c = join '', map {"($_)"} @c;
    if ($c eq "(サ)(シ)(ス)(セ)(ソ)(タ)(チ)(ツ)(テ)(ト)") {
        print qq{ok - 3 \@c = "サシスセソタチツテト" =~ /./g $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 3 \@c = "サシスセソタチツテト" =~ /./g $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 3 \@c = "サシスセソタチツテト" =~ /./g $^X $__FILE__\n};
}

# /g ありのスカラーコンテキスト
@c = ();
while ("サシスセソタチツテト" =~ /(..)/g) {
    push @c, $1;
}
$c = join '', map {"($_)"} @c;
if ($c eq "(サシ)(スセ)(ソタ)(チツ)(テト)") {
    print qq{ok - 4 while ("サシスセソタチツテト" =~ /(..)/g) { } $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 while ("サシスセソタチツテト" =~ /(..)/g) { } $^X $__FILE__\n};
}

#---

# /g なしのスカラーコンテキスト
$success = "アソア" =~ m/ソ/;
if ($success) {
    print qq{ok - 5 "アソア" =~ m/ソ/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 5 "アソア" =~ m/ソ/ $^X $__FILE__\n};
}

# /g なしのリストコンテキスト
if (($c1,$c2,$c3,$c4) = "サシスセソタチツテト" =~ m/^...(.)(.)(.)(.)...$/) {
    if ("($c1)($c2)($c3)($c4)" eq "(セ)(ソ)(タ)(チ)") {
        print qq{ok - 6 "サシスセソタチツテト" =~ m/^...(.)(.)(.)(.)...\$/ $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 6 "サシスセソタチツテト" =~ m/^...(.)(.)(.)(.)...\$/ $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 6 "サシスセソタチツテト" =~ m/^...(.)(.)(.)(.)...\$/ $^X $__FILE__\n};
}

# /g ありのリストコンテキスト
@c = "サシスセソタチツテト" =~ m/./g;
if (@c) {
    $c = join '', map {"($_)"} @c;
    if ($c eq "(サ)(シ)(ス)(セ)(ソ)(タ)(チ)(ツ)(テ)(ト)") {
        print qq{ok - 7 \@c = "サシスセソタチツテト" =~ m/./g $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 7 \@c = "サシスセソタチツテト" =~ m/./g $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 7 \@c = "サシスセソタチツテト" =~ m/./g $^X $__FILE__\n};
}

# /g ありのスカラーコンテキスト
@c = ();
while ("サシスセソタチツテト" =~ m/(..)/g) {
    push @c, $1;
}
$c = join '', map {"($_)"} @c;
if ($c eq "(サシ)(スセ)(ソタ)(チツ)(テト)") {
    print qq{ok - 8 while ("サシスセソタチツテト" =~ m/(..)/g) { } $^X $__FILE__\n};
}
else {
    print qq{not ok - 8 while ("サシスセソタチツテト" =~ m/(..)/g) { } $^X $__FILE__\n};
}

__END__
