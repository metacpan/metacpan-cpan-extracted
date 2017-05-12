# encoding: OldUTF8
# This file is encoded in old UTF-8.
die "This file is not encoded in old UTF-8.\n" if q{あ} ne "\xe3\x81\x82";

use OldUTF8;
print "1..6\n";

my $__FILE__ = __FILE__;

# 「^」という正規表現を使った場合

$_ = "ＡＡＡ\nＢＢＢ\nＣＣＣ";
@_ = split(m/^/, $_);
if (join('', map {"($_)"} @_) eq "(ＡＡＡ\n)(ＢＢＢ\n)(ＣＣＣ)") {
    print qq{ok - 1 \@_ = split(m/^/, \$\_) $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 \@_ = split(m/^/, \$\_) $^X $__FILE__\n};
}

$_ = "ＡＡＡ1\n2ＢＢＢ1\n2ＣＣＣ";
@_ = split(m/^2/, $_);
if (join('', map {"($_)"} @_) eq "(ＡＡＡ1\n)(ＢＢＢ1\n)(ＣＣＣ)") {
    print qq{ok - 2 \@_ = split(m/^2/, \$\_) $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 \@_ = split(m/^2/, \$\_) $^X $__FILE__\n};
    print "<<", join('', map {"($_)"} @_), ">>\n";
}

$_ = "ＡＡＡ1\n2ＢＢＢ1\n2ＣＣＣ";
@_ = split(m/^2/m, $_);
if (join('', map {"($_)"} @_) eq "(ＡＡＡ1\n)(ＢＢＢ1\n)(ＣＣＣ)") {
    print qq{ok - 3 \@_ = split(m/^2/m, \$\_) $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 \@_ = split(m/^2/m, \$\_) $^X $__FILE__\n};
    print "<<", join('', map {"($_)"} @_), ">>\n";
}

$_ = "ＡＡＡ1\n2ＢＢＢ1\n2ＣＣＣ";
@_ = split(m/1^/, $_);
if (join('', map {"($_)"} @_) eq "(ＡＡＡ1\n2ＢＢＢ1\n2ＣＣＣ)") {
    print qq{ok - 4 \@_ = split(m/1^/, \$\_) $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 \@_ = split(m/1^/, \$\_) $^X $__FILE__\n};
}

$_ = "ＡＡＡ1\n2ＢＢＢ1\n2ＣＣＣ";
@_ = split(m/1\n^2/, $_);
if (join('', map {"($_)"} @_) eq "(ＡＡＡ)(ＢＢＢ)(ＣＣＣ)") {
    print qq{ok - 5 \@_ = split(m/1\\n^2/, \$\_) $^X $__FILE__\n};
}
else {
    print qq{not ok - 5 \@_ = split(m/1\\n^2/, \$\_) $^X $__FILE__\n};
    print "<<", join('', map {"($_)"} @_), ">>\n";
}

$_ = "ＡＡＡ1\n2ＢＢＢ1\n2ＣＣＣ";
@_ = split(m/1\n^2/m, $_);
if (join('', map {"($_)"} @_) eq "(ＡＡＡ)(ＢＢＢ)(ＣＣＣ)") {
    print qq{ok - 6 \@_ = split(m/1\\n^2/m, \$\_) $^X $__FILE__\n};
}
else {
    print qq{not ok - 6 \@_ = split(m/1\\n^2/m, \$\_) $^X $__FILE__\n};
    print "<<", join('', map {"($_)"} @_), ">>\n";
}

__END__
