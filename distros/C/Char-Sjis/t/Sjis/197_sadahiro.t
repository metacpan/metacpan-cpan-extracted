# encoding: Sjis
# This file is encoded in ShiftJIS.
die "This file is not encoded in ShiftJIS.\n" if q{あ} ne "\x82\xa0";

use Sjis;
print "1..10\n";

my $__FILE__ = __FILE__;

# 単語境界を扱うメタ文字 C<\b> および C<\B> は正しく動作しません。

if ('ABC アDEF GHI' =~ /\bDEF/) {
    print "not ok - 1 $^X $__FILE__ ('ABC アDEF GHI' =~ /\\bDEF/)\n";
}
else {
    print "ok - 1 $^X $__FILE__ ('ABC アDEF GHI' =~ /\\bDEF/)\n";
}

if ('ABC アDEF GHI' =~ /DEF\b/) {
    print "ok - 2 $^X $__FILE__ ('ABC アDEF GHI' =~ /DEF\\b/)\n";
}
else {
    print "not ok - 2 $^X $__FILE__ ('ABC アDEF GHI' =~ /DEF\\b/)\n";
}

if ('ABC アDEF GHI' =~ /\bDEF\b/) {
    print "not ok - 3 $^X $__FILE__ ('ABC アDEF GHI' =~ /\\bDEF\\b/)\n";
}
else {
    print "ok - 3 $^X $__FILE__ ('ABC アDEF GHI' =~ /\\bDEF\\b/)\n";
}

if ('ABC アDEF GHI' =~ /\bABC/) {
    print "ok - 4 $^X $__FILE__ ('ABC アDEF GHI' =~ /\\bABC/)\n";
}
else {
    print "not ok - 4 $^X $__FILE__ ('ABC アDEF GHI' =~ /\\bABC/)\n";
}

if ('ABC アDEF GHI' =~ /GHI\b/) {
    print "ok - 5 $^X $__FILE__ ('ABC アDEF GHI' =~ /GHI\\b/)\n";
}
else {
    print "not ok - 5 $^X $__FILE__ ('ABC アDEF GHI' =~ /GHI\\b/)\n";
}

if ('ABC アDEF GHI' =~ /\BアDEF G/) {
    print "ok - 6 $^X $__FILE__ ('ABC アDEF GHI' =~ /\\BアDEF G/)\n";
}
else {
    print "not ok - 6 $^X $__FILE__ ('ABC アDEF GHI' =~ /\\BアDEF G/)\n";
}

if ('ABC アDEF GHI' =~ /アDEF G\B/) {
    print "ok - 7 $^X $__FILE__ ('ABC アDEF GHI' =~ /アDEF G\\B/)\n";
}
else {
    print "not ok - 7 $^X $__FILE__ ('ABC アDEF GHI' =~ /アDEF G\\B/)\n";
}

if ('ABC アDEF GHI' =~ /\BアDEF G\B/) {
    print "ok - 8 $^X $__FILE__ ('ABC アDEF GHI' =~ /\\BアDEF G\\B/)\n";
}
else {
    print "not ok - 8 $^X $__FILE__ ('ABC アDEF GHI' =~ /\\BアDEF G\\B/)\n";
}

if ('ABC アDEF GHI' =~ /\BABC/) {
    print "not ok - 9 $^X $__FILE__ ('ABC アDEF GHI' =~ /\\BABC/)\n";
}
else {
    print "ok - 9 $^X $__FILE__ ('ABC アDEF GHI' =~ /\\BABC/)\n";
}

if ('ABC アDEF GHI' =~ /GHI\B/) {
    print "not ok - 10 $^X $__FILE__ ('ABC アDEF GHI' =~ /GHI\\B/)\n";
}
else {
    print "ok - 10 $^X $__FILE__ ('ABC アDEF GHI' =~ /GHI\\B/)\n";
}

__END__

