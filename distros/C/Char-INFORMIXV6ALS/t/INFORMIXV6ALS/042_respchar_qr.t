# encoding: INFORMIXV6ALS
# This file is encoded in INFORMIX V6 ALS.
die "This file is not encoded in INFORMIX V6 ALS.\n" if q{あ} ne "\x82\xa0";

use INFORMIXV6ALS;
print "1..20\n";

my $__FILE__ = __FILE__;

if ("ソアア" =~ qr/^ソ/) {
    print qq{ok - 1 "ソアア" =~ qr/^ソ/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 "ソアア" =~ qr/^ソ/ $^X $__FILE__\n};
}

if ("アソア" !~ qr/^ソ/) {
    print qq{ok - 2 "アソア" !~ qr/^ソ/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 "アソア" !~ qr/^ソ/ $^X $__FILE__\n};
}

if ("アアソ" =~ qr/ソ$/) {
    print qq{ok - 3 "アアソ" =~ qr/ソ\$/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 "アアソ" =~ qr/ソ\$/ $^X $__FILE__\n};
}

if ("アソア" !~ qr/ソ$/) {
    print qq{ok - 4 "アソア" !~ qr/ソ\$/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 "アソア" !~ qr/ソ\$/ $^X $__FILE__\n};
}

if ("アソア" =~ qr/(ア([イソウ])ア)/) {
    if ($1 eq "アソア") {
        if ($2 eq "ソ") {
            print qq{ok - 5 "アソア" =~ qr/(ア([イソウ])ア)/ \$1=($1), \$2=($2) $^X $__FILE__\n};
        }
        else {
            print qq{not ok - 5 "アソア" =~ qr/(ア([イソウ])ア)/ \$1=($1), \$2=($2) $^X $__FILE__\n};
        }
    }
    else {
        print qq{not ok - 5 "アソア" =~ qr/(ア([イソウ])ア)/ \$1=($1), \$2=($2) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 5 "アソア" =~ qr/(ア([イソウ])ア)/ \$1=($1), \$2=($2) $^X $__FILE__\n};
}

if ("アソア" !~ qr/(ア([イウエ])ア)/) {
    print qq{ok - 6 "アソア" !~ qr/(ア([イウエ])ア)/ \$1=($1), \$2=($2) $^X $__FILE__\n};
}
else {
    print qq{not ok - 6 "アソア" !~ qr/(ア([イソウ])ア)/ \$1=($1), \$2=($2) $^X $__FILE__\n};
}

if ("アソア" =~ qr/(アソ|イソ)/) {
    if ($1 eq "アソ") {
        print qq{ok - 7 "アソア" =~ qr/(アソ|イソ)/ \$1=($1) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 7 "アソア" =~ qr/(アソ|イソ)/ \$1=($1) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 7 "アソア" =~ qr/(アソ|イソ)/ \$1=($1) $^X $__FILE__\n};
}

if ("アソア" !~ qr/(アイ|イウ)/) {
    print qq{ok - 8 "アソア" !~ qr/(アイ|イウ)/ \$1=($1) $^X $__FILE__\n};
}
else {
    print qq{not ok - 8 "アソア" !~ qr/(アイ|イウ)/ \$1=($1) $^X $__FILE__\n};
}

if ("アソソ" =~ qr/(アソ?)/) {
    if ($1 eq "アソ") {
        print qq{ok - 9 "アソソ" =~ qr/(アソ?)/ \$1=($1) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 9 "アソソ" =~ qr/(アソ?)/ \$1=($1) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 9 "アソソ" =~ qr/(アソ?)/ \$1=($1) $^X $__FILE__\n};
}

if ("アソソ" !~ qr/(イソ?)/) {
    print qq{ok - 10 "アソソ" !~ qr/(イソ?)/ \$1=($1) $^X $__FILE__\n};
}
else {
    print qq{not ok - 10 "アソソ" !~ qr/(イソ?)/ \$1=($1) $^X $__FILE__\n};
}

if ("アソソ" =~ qr/(アソソ?)/) {
    if ($1 eq "アソソ") {
        print qq{ok - 11 "アソソ" =~ qr/(アソソ?)/ \$1=($1) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 11 "アソソ" =~ qr/(アソソ?)/ \$1=($1) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 11 "アソソ" =~ qr/(アソソ?)/ \$1=($1) $^X $__FILE__\n};
}

if ("アソソ" !~ qr/(イソソ?)/) {
    print qq{ok - 12 "アソソ" !~ qr/(イソソ?)/ \$1=($1) $^X $__FILE__\n};
}
else {
    print qq{not ok - 12 "アソソ" !~ qr/(イソソ?)/ \$1=($1) $^X $__FILE__\n};
}

if ("アソソ" =~ qr/(アソ+)/) {
    if ($1 eq "アソソ") {
        print qq{ok - 13 "アソソ" =~ qr/(アソ+)/ \$1=($1) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 13 "アソソ" =~ qr/(アソ+)/ \$1=($1) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 13 "アソソ" =~ qr/(アソ+)/ \$1=($1) $^X $__FILE__\n};
}

if ("アソソ" !~ qr/(イソ+)/) {
    print qq{ok - 14 "アソソ" !~ qr/(イソ+)/ \$1=($1) $^X $__FILE__\n};
}
else {
    print qq{not ok - 14 "アソソ" !~ qr/(イソ+)/ \$1=($1) $^X $__FILE__\n};
}

if ("アソソ" =~ qr/(アソ*)/) {
    if ($1 eq "アソソ") {
        print qq{ok - 15 "アソソ" =~ qr/(アソ*)/ \$1=($1) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 15 "アソソ" =~ qr/(アソ*)/ \$1=($1) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 15 "アソソ" =~ qr/(アソ*)/ \$1=($1) $^X $__FILE__\n};
}

if ("アソソ" !~ qr/(イソ*)/) {
    print qq{ok - 16 "アソソ" !~ qr/(イソ*)/ \$1=($1) $^X $__FILE__\n};
}
else {
    print qq{not ok - 16 "アソソ" !~ qr/(イソ*)/ \$1=($1) $^X $__FILE__\n};
}

if ("アソソ" =~ qr/(ア.)/) {
    if ($1 eq "アソ") {
        print qq{ok - 17 "アソソ" =~ qr/(ア.)/ \$1=($1) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 17 "アソソ" =~ qr/(ア.)/ \$1=($1) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 17 "アソソ" =~ qr/(ア.)/ \$1=($1) $^X $__FILE__\n};
}

if ("アソソ" !~ qr/(イ.)/) {
    print qq{ok - 18 "アソソ" !~ qr/(イ.)/ \$1=($1) $^X $__FILE__\n};
}
else {
    print qq{not ok - 18 "アソソ" !~ qr/(イ.)/ \$1=($1) $^X $__FILE__\n};
}

if ("アソソ" =~ qr/(ア.{2})/) {
    if ($1 eq "アソソ") {
        print qq{ok - 19 "アソソ" =~ qr/(ア.{2})/ \$1=($1) $^X $__FILE__\n};
    }
    else {
        print qq{not ok - 19 "アソソ" =~ qr/(ア.{2})/ \$1=($1) $^X $__FILE__\n};
    }
}
else {
    print qq{not ok - 19 "アソソ" =~ qr/(ア.{2})/ \$1=($1) $^X $__FILE__\n};
}

if ("アソソ" !~ qr/(イ.{2})/) {
    print qq{ok - 20 "アソソ" !~ qr/(イ.{2})/ \$1=($1) $^X $__FILE__\n};
}
else {
    print qq{not ok - 20 "アソソ" !~ qr/(イ.{2})/ \$1=($1) $^X $__FILE__\n};
}

__END__
