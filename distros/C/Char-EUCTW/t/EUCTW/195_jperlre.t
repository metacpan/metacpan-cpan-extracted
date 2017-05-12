# encoding: EUCTW
# This file is encoded in EUC-TW.
die "This file is not encoded in EUC-TW.\n" if q{あ} ne "\xa4\xa2";

use EUCTW;
print "1..7\n";

my $__FILE__ = __FILE__;

if ('ABC DEF GHI' =~ /\BABC/) {
    print "not ok - 1 $^X $__FILE__ ('ABC DEF GHI' =~ /\\BABC/)\n";
}
else {
    print "ok - 1 $^X $__FILE__ ('ABC DEF GHI' =~ /\\BABC/)\n";
}

if ('アABC DEF GHI' =~ /\BABC/) {
    print "not ok - 2 $^X $__FILE__ ('アABC DEF GHI' =~ /\\BABC/)\n";
}
else {
    print "ok - 2 $^X $__FILE__ ('アABC DEF GHI' =~ /\\BABC/)\n";
}

if ('アABC DEF GHI' =~ /\BDEF/) {
    print "not ok - 3 $^X $__FILE__ ('アABC DEF GHI' =~ /\\BDEF/)\n";
}
else {
    print "ok - 3 $^X $__FILE__ ('アABC DEF GHI' =~ /\\BDEF/)\n";
}

if ('アABC DEF GHI' =~ /\BGHI/) {
    print "not ok - 4 $^X $__FILE__ ('アABC DEF GHI' =~ /\\BGHI/)\n";
}
else {
    print "ok - 4 $^X $__FILE__ ('アABC DEF GHI' =~ /\\BGHI/)\n";
}

if ('アABC DEF GHI' =~ /ABC\B/) {
    print "not ok - 5 $^X $__FILE__ ('アABC DEF GHI' =~ /ABC\\B/)\n";
}
else {
    print "ok - 5 $^X $__FILE__ ('アABC DEF GHI' =~ /ABC\\B/)\n";
}

if ('アABC DEF GHI' =~ /DEF\B/) {
    print "not ok - 6 $^X $__FILE__ ('アABC DEF GHI' =~ /DEF\\B/)\n";
}
else {
    print "ok - 6 $^X $__FILE__ ('アABC DEF GHI' =~ /DEF\\B/)\n";
}

if ('アABC DEF GHI' =~ /GHI\B/) {
    print "not ok - 7 $^X $__FILE__ ('アABC DEF GHI' =~ /GHI\\B/)\n";
}
else {
    print "ok - 7 $^X $__FILE__ ('アABC DEF GHI' =~ /GHI\\B/)\n";
}

__END__
