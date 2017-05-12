# encoding: UTF2
# This file is encoded in UTF-2.
die "This file is not encoded in UTF-2.\n" if q{あ} ne "\xe3\x81\x82";

use UTF2;
print "1..3\n";

my $__FILE__ = __FILE__;

# tr///c
$a = "カキクケコサシスセソタチツテト";
if ($a =~ tr/サシスセソ/さしすせそ/c) {
    print qq{ok - 1 \$a =~ tr/サシスセソ/さしすせそ/c ($a) $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 \$a =~ tr/サシスセソ/さしすせそ/c ($a) $^X $__FILE__\n};
}

# tr///d
$a = "カキクケコサシスセソタチツテト";
if ($a =~ tr/サシスセソ//d) {
    print qq{ok - 2 \$a =~ tr/サシスセソ//d ($a) $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 \$a =~ tr/サシスセソ//d ($a) $^X $__FILE__\n};
}

# tr///s
$a = "カキクケコサシスセソタチツテト";
if ($a =~ tr/サシスセソ/ナ/s) {
    print qq{ok - 3 \$a =~ tr/サシスセソ/ナ/s ($a) $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 \$a =~ tr/サシスセソ/ナ/s ($a) $^X $__FILE__\n};
}

__END__
