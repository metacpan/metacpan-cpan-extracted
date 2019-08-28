# encoding: Big5HKSCS
# This file is encoded in Big5-HKSCS.
die "This file is not encoded in Big5-HKSCS.\n" if q{あ} ne "\x82\xa0";

use Big5HKSCS;
print "1..40\n";

my $__FILE__ = __FILE__;

if ("ソアア" =~ /^ソ/) {
    print qq{ok - 1 "ソアア" =~ /^ソ/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 "ソアア" =~ /^ソ/ $^X $__FILE__\n};
}

if ("アソア" !~ /^ソ/) {
    print qq{ok - 2 "アソア" !~ /^ソ/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 "アソア" !~ /^ソ/ $^X $__FILE__\n};
}

if ("アアソ" =~ /ソ$/) {
    print qq{ok - 3 "アアソ" =~ /ソ\$/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 "アアソ" =~ /ソ\$/ $^X $__FILE__\n};
}

if ("アソア" !~ /ソ$/) {
    print qq{ok - 4 "アソア" !~ /ソ\$/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 "アソア" !~ /ソ\$/ $^X $__FILE__\n};
}

if ("アソア" =~ /(ア([イソウ])ア)/) {
    if ($1 eq "アソア") {
        if ($2 eq "ソ") {
            print qq{ok - 5 "アソア" =~ /(ア([イソウ])ア)/ \$1=($1), \$2=($2) $^X $__FILE__\n};
        }
        else {
            print qq{not ok - 5 "アソア" =~ /(ア([イソウ])ア)/ \$1=($1), \$2=($2) $^X $__FILE__\n};
        }
    }
    else {
        print qq{not ok - 5 "アソア" =~ /(ア([イソウ])ア)/ \$1=($1), \$2=($2) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 5 "アソア" =~ /(ア([イソウ])ア)/ \$1=($1), \$2=($2) $^X $__FILE__\n};
}

if ("アソア" !~ /(ア([イウエ])ア)/) {
    print qq{ok - 6  "アソア" !~ /(ア([イウエ])ア)/ \$1=($1), \$2=($2) $^X $__FILE__\n};
}
else {
    print qq{not ok - 6 "アソア" !~ /(ア([イソウ])ア)/ \$1=($1), \$2=($2) $^X $__FILE__\n};
}

if ("アソア" =~ /(アソ|イソ)/) {
    if ($1 eq "アソ") {
        print qq{ok - 7 "アソア" =~ /(アソ|イソ)/ \$1=($1) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 7 "アソア" =~ /(アソ|イソ)/ \$1=($1) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 7 "アソア" =~ /(アソ|イソ)/ \$1=($1) $^X $__FILE__\n};
}

if ("アソア" !~ /(アイ|イウ)/) {
    print qq{ok - 8 "アソア" !~ /(アイ|イウ)/ \$1=($1) $^X $__FILE__\n};
}
else {
    print qq{not ok - 8 "アソア" !~ /(アイ|イウ)/ \$1=($1) $^X $__FILE__\n};
}

if ("アソソ" =~ /(アソ?)/) {
    if ($1 eq "アソ") {
        print qq{ok - 9 "アソソ" =~ /(アソ?)/ \$1=($1) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 9 "アソソ" =~ /(アソ?)/ \$1=($1) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 9 "アソソ" =~ /(アソ?)/ \$1=($1) $^X $__FILE__\n};
}

if ("アソソ" !~ /(イソ?)/) {
    print qq{ok - 10 "アソソ" !~ /(イソ?)/ \$1=($1) $^X $__FILE__\n};
}
else {
    print qq{not ok - 10 "アソソ" !~ /(イソ?)/ \$1=($1) $^X $__FILE__\n};
}

if ("アソソ" =~ /(アソソ?)/) {
    if ($1 eq "アソソ") {
        print qq{ok - 11 "アソソ" =~ /(アソソ?)/ \$1=($1) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 11 "アソソ" =~ /(アソソ?)/ \$1=($1) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 11 "アソソ" =~ /(アソソ?)/ \$1=($1) $^X $__FILE__\n};
}

if ("アソソ" !~ /(イソソ?)/) {
    print qq{ok - 12 "アソソ" !~ /(イソソ?)/ \$1=($1) $^X $__FILE__\n};
}
else {
    print qq{not ok - 12 "アソソ" !~ /(イソソ?)/ \$1=($1) $^X $__FILE__\n};
}

if ("アソソ" =~ /(アソ+)/) {
    if ($1 eq "アソソ") {
        print qq{ok - 13 "アソソ" =~ /(アソ+)/ \$1=($1) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 13 "アソソ" =~ /(アソ+)/ \$1=($1) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 13 "アソソ" =~ /(アソ+)/ \$1=($1) $^X $__FILE__\n};
}

if ("アソソ" !~ /(イソ+)/) {
    print qq{ok - 14 "アソソ" !~ /(イソ+)/ \$1=($1) $^X $__FILE__\n};
}
else {
    print qq{not ok - 14 "アソソ" !~ /(イソ+)/ \$1=($1) $^X $__FILE__\n};
}

if ("アソソ" =~ /(アソ*)/) {
    if ($1 eq "アソソ") {
        print qq{ok - 15 "アソソ" =~ /(アソ*)/ \$1=($1) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 15 "アソソ" =~ /(アソ*)/ \$1=($1) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 15 "アソソ" =~ /(アソ*)/ \$1=($1) $^X $__FILE__\n};
}

if ("アソソ" !~ /(イソ*)/) {
    print qq{ok - 16 "アソソ" !~ /(イソ*)/ \$1=($1) $^X $__FILE__\n};
}
else {
    print qq{not ok - 16 "アソソ" !~ /(イソ*)/ \$1=($1) $^X $__FILE__\n};
}

if ("アソソ" =~ /(ア.)/) {
    if ($1 eq "アソ") {
        print qq{ok - 17 "アソソ" =~ /(ア.)/ \$1=($1) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 17 "アソソ" =~ /(ア.)/ \$1=($1) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 17 "アソソ" =~ /(ア.)/ \$1=($1) $^X $__FILE__\n};
}

if ("アソソ" !~ /(イ.)/) {
    print qq{ok - 18 "アソソ" !~ /(イ.)/ \$1=($1) $^X $__FILE__\n};
}
else {
    print qq{not ok - 18 "アソソ" !~ /(イ.)/ \$1=($1) $^X $__FILE__\n};
}

if ("アソソ" =~ /(ア.{2})/) {
    if ($1 eq "アソソ") {
        print qq{ok - 19 "アソソ" =~ /(ア.{2})/ \$1=($1) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 19 "アソソ" =~ /(ア.{2})/ \$1=($1) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 19 "アソソ" =~ /(ア.{2})/ \$1=($1) $^X $__FILE__\n};
}

if ("アソソ" !~ /(イ.{2})/) {
    print qq{ok - 20 "アソソ" !~ /(イ.{2})/ \$1=($1) $^X $__FILE__\n};
}
else {
    print qq{not ok - 20 "アソソ" !~ /(イ.{2})/ \$1=($1) $^X $__FILE__\n};
}

#---

if ("ソアア" =~ m/^ソ/) {
    print qq{ok - 21 "ソアア" =~ m/^ソ/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 21 "ソアア" =~ m/^ソ/ $^X $__FILE__\n};
}

if ("アソア" !~ m/^ソ/) {
    print qq{ok - 22 "アソア" !~ m/^ソ/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 22 "アソア" !~ m/^ソ/ $^X $__FILE__\n};
}

if ("アアソ" =~ m/ソ$/) {
    print qq{ok - 23 "アアソ" =~ m/ソ\$/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 23 "アアソ" =~ m/ソ\$/ $^X $__FILE__\n};
}

if ("アソア" !~ m/ソ$/) {
    print qq{ok - 24 "アソア" !~ m/ソ\$/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 24 "アソア" !~ m/ソ\$/ $^X $__FILE__\n};
}

if ("アソア" =~ m/(ア([イソウ])ア)/) {
    if ($1 eq "アソア") {
        if ($2 eq "ソ") {
            print qq{ok - 25 "アソア" =~ m/(ア([イソウ])ア)/ \$1=($1), \$2=($2) $^X $__FILE__\n};
        }
        else {
            print qq{not ok - 25 "アソア" =~ m/(ア([イソウ])ア)/ \$1=($1), \$2=($2) $^X $__FILE__\n};
        }
    }
    else {
        print qq{not ok - 25 "アソア" =~ m/(ア([イソウ])ア)/ \$1=($1), \$2=($2) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 25 "アソア" =~ m/(ア([イソウ])ア)/ \$1=($1), \$2=($2) $^X $__FILE__\n};
}

if ("アソア" !~ m/(ア([イウエ])ア)/) {
    print qq{ok - 26 "アソア" !~ m/(ア([イウエ])ア)/ \$1=($1), \$2=($2) $^X $__FILE__\n};
}
else {
    print qq{not ok - 26 "アソア" !~ m/(ア([イソウ])ア)/ \$1=($1), \$2=($2) $^X $__FILE__\n};
}

if ("アソア" =~ m/(アソ|イソ)/) {
    if ($1 eq "アソ") {
        print qq{ok - 27 "アソア" =~ m/(アソ|イソ)/ \$1=($1) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 27 "アソア" =~ m/(アソ|イソ)/ \$1=($1) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 27 "アソア" =~ m/(アソ|イソ)/ \$1=($1) $^X $__FILE__\n};
}

if ("アソア" !~ m/(アイ|イウ)/) {
    print qq{ok - 28 "アソア" !~ m/(アイ|イウ)/ \$1=($1) $^X $__FILE__\n};
}
else {
    print qq{not ok - 28 "アソア" !~ m/(アイ|イウ)/ \$1=($1) $^X $__FILE__\n};
}

if ("アソソ" =~ m/(アソ?)/) {
    if ($1 eq "アソ") {
        print qq{ok - 29 "アソソ" =~ m/(アソ?)/ \$1=($1) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 29 "アソソ" =~ m/(アソ?)/ \$1=($1) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 29 "アソソ" =~ m/(アソ?)/ \$1=($1) $^X $__FILE__\n};
}

if ("アソソ" !~ m/(イソ?)/) {
    print qq{ok - 30 "アソソ" !~ m/(イソ?)/ \$1=($1) $^X $__FILE__\n};
}
else {
    print qq{not ok - 30 "アソソ" !~ m/(イソ?)/ \$1=($1) $^X $__FILE__\n};
}

if ("アソソ" =~ m/(アソソ?)/) {
    if ($1 eq "アソソ") {
        print qq{ok - 31 "アソソ" =~ m/(アソソ?)/ \$1=($1) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 31 "アソソ" =~ m/(アソソ?)/ \$1=($1) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 31 "アソソ" =~ m/(アソソ?)/ \$1=($1) $^X $__FILE__\n};
}

if ("アソソ" !~ m/(イソソ?)/) {
    print qq{ok - 32 "アソソ" !~ m/(イソソ?)/ \$1=($1) $^X $__FILE__\n};
}
else {
    print qq{not ok - 32 "アソソ" !~ m/(イソソ?)/ \$1=($1) $^X $__FILE__\n};
}

if ("アソソ" =~ m/(アソ+)/) {
    if ($1 eq "アソソ") {
        print qq{ok - 33 "アソソ" =~ m/(アソ+)/ \$1=($1) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 33 "アソソ" =~ m/(アソ+)/ \$1=($1) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 33 "アソソ" =~ m/(アソ+)/ \$1=($1) $^X $__FILE__\n};
}

if ("アソソ" !~ m/(イソ+)/) {
    print qq{ok - 34 "アソソ" !~ m/(イソ+)/ \$1=($1) $^X $__FILE__\n};
}
else {
    print qq{not ok - 34 "アソソ" !~ m/(イソ+)/ \$1=($1) $^X $__FILE__\n};
}

if ("アソソ" =~ m/(アソ*)/) {
    if ($1 eq "アソソ") {
        print qq{ok - 35 "アソソ" =~ m/(アソ*)/ \$1=($1) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 35 "アソソ" =~ m/(アソ*)/ \$1=($1) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 35 "アソソ" =~ m/(アソ*)/ \$1=($1) $^X $__FILE__\n};
}

if ("アソソ" !~ m/(イソ*)/) {
    print qq{ok - 36 "アソソ" !~ m/(イソ*)/ \$1=($1) $^X $__FILE__\n};
}
else {
    print qq{not ok - 36 "アソソ" !~ m/(イソ*)/ \$1=($1) $^X $__FILE__\n};
}

if ("アソソ" =~ m/(ア.)/) {
    if ($1 eq "アソ") {
        print qq{ok - 37 "アソソ" =~ m/(ア.)/ \$1=($1) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 37 "アソソ" =~ m/(ア.)/ \$1=($1) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 37 "アソソ" =~ m/(ア.)/ \$1=($1) $^X $__FILE__\n};
}

if ("アソソ" !~ m/(イ.)/) {
    print qq{ok - 38 "アソソ" !~ m/(イ.)/ \$1=($1) $^X $__FILE__\n};
}
else {
    print qq{not ok - 38 "アソソ" !~ m/(イ.)/ \$1=($1) $^X $__FILE__\n};
}

if ("アソソ" =~ m/(ア.{2})/) {
    if ($1 eq "アソソ") {
        print qq{ok - 39 "アソソ" =~ m/(ア.{2})/ \$1=($1) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 39 "アソソ" =~ m/(ア.{2})/ \$1=($1) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 39 "アソソ" =~ m/(ア.{2})/ \$1=($1) $^X $__FILE__\n};
}

if ("アソソ" !~ m/(イ.{2})/) {
    print qq{ok - 40 "アソソ" !~ m/(イ.{2})/ \$1=($1) $^X $__FILE__\n};
}
else {
    print qq{not ok - 40 "アソソ" !~ m/(イ.{2})/ \$1=($1) $^X $__FILE__\n};
}

__END__
