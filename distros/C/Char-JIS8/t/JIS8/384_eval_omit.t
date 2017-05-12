# encoding: JIS8
# This file is encoded in JIS8.
die "This file is not encoded in JIS8.\n" if q{‚ } ne "\x82\xa0";

use JIS8;

print "1..12\n";

# eval (omit) has eval "..."
$_ = <<'END';
eval JIS8::escape " if (JIS8::length(q{²ÛÊÆÎÍÄÁØÇÙ¦Ü¶ÖÀÚ¿ÂÈÅ×Ñ³²Éµ¸ÔÏ¹Ìº´Ã±»·ÕÒÐ¼´ËÓ¾½}) == 47) { return 1 } else { return 0 } "
END
if (eval JIS8::escape) {
    print qq{ok - 1 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 1 $^X @{[__FILE__]}\n};
}

# eval (omit) has eval qq{...}
$_ = <<'END';
eval JIS8::escape qq{ if (JIS8::length(q{²ÛÊÆÎÍÄÁØÇÙ¦Ü¶ÖÀÚ¿ÂÈÅ×Ñ³²Éµ¸ÔÏ¹Ìº´Ã±»·ÕÒÐ¼´ËÓ¾½}) == 47) { return 1 } else { return 0 } }
END
if (eval JIS8::escape) {
    print qq{ok - 2 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 2 $^X @{[__FILE__]}\n};
}

# eval (omit) has eval '...'
$_ = <<'END';
eval JIS8::escape ' if (JIS8::length(q{²ÛÊÆÎÍÄÁØÇÙ¦Ü¶ÖÀÚ¿ÂÈÅ×Ñ³²Éµ¸ÔÏ¹Ìº´Ã±»·ÕÒÐ¼´ËÓ¾½}) == 47) { return 1 } else { return 0 } '
END
if (eval JIS8::escape) {
    print qq{ok - 3 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 3 $^X @{[__FILE__]}\n};
}

# eval (omit) has eval q{...}
$_ = <<'END';
eval JIS8::escape q{ if (JIS8::length(q{²ÛÊÆÎÍÄÁØÇÙ¦Ü¶ÖÀÚ¿ÂÈÅ×Ñ³²Éµ¸ÔÏ¹Ìº´Ã±»·ÕÒÐ¼´ËÓ¾½}) == 47) { return 1 } else { return 0 } }
END
if (eval JIS8::escape) {
    print qq{ok - 4 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 4 $^X @{[__FILE__]}\n};
}

# eval (omit) has eval $var
$_ = <<'END';
eval JIS8::escape $var2
END
my $var2 = q{ if (JIS8::length(q{²ÛÊÆÎÍÄÁØÇÙ¦Ü¶ÖÀÚ¿ÂÈÅ×Ñ³²Éµ¸ÔÏ¹Ìº´Ã±»·ÕÒÐ¼´ËÓ¾½}) == 47) { return 1 } else { return 0 } };
if (eval JIS8::escape) {
    print qq{ok - 5 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 5 $^X @{[__FILE__]}\n};
}

# eval (omit) has eval (omit)
$_ = <<'END';
$_ = "if (JIS8::length(q{²ÛÊÆÎÍÄÁØÇÙ¦Ü¶ÖÀÚ¿ÂÈÅ×Ñ³²Éµ¸ÔÏ¹Ìº´Ã±»·ÕÒÐ¼´ËÓ¾½}) == 47) { return 1 } else { return 0 }";
eval JIS8::escape
END
if (eval JIS8::escape) {
    print qq{ok - 6 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 6 $^X @{[__FILE__]}\n};
}

# eval (omit) has eval {...}
$_ = <<'END';
eval { if (JIS8::length(q{²ÛÊÆÎÍÄÁØÇÙ¦Ü¶ÖÀÚ¿ÂÈÅ×Ñ³²Éµ¸ÔÏ¹Ìº´Ã±»·ÕÒÐ¼´ËÓ¾½}) == 47) { return 1 } else { return 0 } }
END
if (eval JIS8::escape) {
    print qq{ok - 7 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 7 $^X @{[__FILE__]}\n};
}

# eval (omit) has "..."
$_ = <<'END';
if (JIS8::length(q{²ÛÊÆÎÍÄÁØÇÙ¦Ü¶ÖÀÚ¿ÂÈÅ×Ñ³²Éµ¸ÔÏ¹Ìº´Ã±»·ÕÒÐ¼´ËÓ¾½}) == 47) { return "1" } else { return "0" }
END
if (eval JIS8::escape) {
    print qq{ok - 8 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 8 $^X @{[__FILE__]}\n};
}

# eval (omit) has qq{...}
$_ = <<'END';
if (JIS8::length(q{²ÛÊÆÎÍÄÁØÇÙ¦Ü¶ÖÀÚ¿ÂÈÅ×Ñ³²Éµ¸ÔÏ¹Ìº´Ã±»·ÕÒÐ¼´ËÓ¾½}) == 47) { return qq{1} } else { return qq{0} }
END
if (eval JIS8::escape) {
    print qq{ok - 9 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 9 $^X @{[__FILE__]}\n};
}

# eval (omit) has '...'
$_ = <<'END';
if (JIS8::length(q{²ÛÊÆÎÍÄÁØÇÙ¦Ü¶ÖÀÚ¿ÂÈÅ×Ñ³²Éµ¸ÔÏ¹Ìº´Ã±»·ÕÒÐ¼´ËÓ¾½}) == 47) { return '1' } else { return '0' }
END
if (eval JIS8::escape) {
    print qq{ok - 10 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 10 $^X @{[__FILE__]}\n};
}

# eval (omit) has q{...}
$_ = <<'END';
if (JIS8::length(q{²ÛÊÆÎÍÄÁØÇÙ¦Ü¶ÖÀÚ¿ÂÈÅ×Ñ³²Éµ¸ÔÏ¹Ìº´Ã±»·ÕÒÐ¼´ËÓ¾½}) == 47) { return q{1} } else { return q{0} }
END
if (eval JIS8::escape) {
    print qq{ok - 11 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 11 $^X @{[__FILE__]}\n};
}

# eval (omit) has $var
$_ = <<'END';
if (JIS8::length(q{²ÛÊÆÎÍÄÁØÇÙ¦Ü¶ÖÀÚ¿ÂÈÅ×Ñ³²Éµ¸ÔÏ¹Ìº´Ã±»·ÕÒÐ¼´ËÓ¾½}) == 47) { return $var1 } else { return $var0 }
END
my $var1 = 1;
my $var0 = 0;
if (eval JIS8::escape) {
    print qq{ok - 12 $^X @{[__FILE__]}\n};
}
else {
    print qq{not ok - 12 $^X @{[__FILE__]}\n};
}

__END__
