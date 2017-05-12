# encoding: UHC
# This file is encoded in UHC.
die "This file is not encoded in UHC.\n" if q{궇} ne "\x82\xa0";

use UHC;
print "1..4\n";

my $__FILE__ = __FILE__;

$_ = '궇궋궎궑궓궇궋궎궑궓';
if (rindex($_,'궋궎') == 12) {
    print qq{ok - 1 rindex(\$_,'궋궎') == 12 $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 rindex(\$_,'궋궎') == 12 $^X $__FILE__\n};
}

$_ = '궇궋궎궑궓궇궋궎궑궓';
if (rindex($_,'궋궎',10) == 2) {
    print qq{ok - 2 rindex(\$_,'궋궎',10) == 2 $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 rindex(\$_,'궋궎',10) == 2 $^X $__FILE__\n};
}

$_ = '궇궋궎궑궓궇궋궎궑궓';
if (UHC::rindex($_,'궋궎') == 6) {
    print qq{ok - 3 UHC::rindex(\$_,'궋궎') == 6 $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 UHC::rindex(\$_,'궋궎') == 6 $^X $__FILE__\n};
}

$_ = '궇궋궎궑궓궇궋궎궑궓';
if (UHC::rindex($_,'궋궎',5) == 1) {
    print qq{ok - 4 UHC::rindex(\$_,'궋궎',5) == 1 $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 UHC::rindex(\$_,'궋궎',5) == 1 $^X $__FILE__\n};
}

__END__
