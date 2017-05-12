# encoding: UHC
# This file is encoded in UHC.
die "This file is not encoded in UHC.\n" if q{궇} ne "\x82\xa0";

use UHC;
print "1..20\n";

my $__FILE__ = __FILE__;

if ("궶" !~ /[궸-궺]/i) {
    print qq{ok - 1 "궶"!~/[궸-궺]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 "궶"!~/[궸-궺]/i $^X $__FILE__\n};
}

if ("궸" =~ /[궸-궺]/i) {
    print qq{ok - 2 "궸"=~/[궸-궺]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 "궸"=~/[궸-궺]/i $^X $__FILE__\n};
}

if ("궹" =~ /[궸-궺]/i) {
    print qq{ok - 3 "궹"=~/[궸-궺]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 "궹"=~/[궸-궺]/i $^X $__FILE__\n};
}

if ("궺" =~ /[궸-궺]/i) {
    print qq{ok - 4 "궺"=~/[궸-궺]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 "궺"=~/[궸-궺]/i $^X $__FILE__\n};
}

if ("궻" !~ /[궸-궺]/i) {
    print qq{ok - 5 "궻"!~/[궸-궺]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 5 "궻"!~/[궸-궺]/i $^X $__FILE__\n};
}

my $from = '궸';
if ("궶" !~ /[$from-궺]/i) {
    print qq{ok - 6 "궶"!~/[\$from-궺]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 6 "궶"!~/[\$from-궺]/i $^X $__FILE__\n};
}

if ("궸" =~ /[$from-궺]/i) {
    print qq{ok - 7 "궸"=~/[\$from-궺]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 7 "궸"=~/[\$from-궺]/i $^X $__FILE__\n};
}

if ("궹" =~ /[$from-궺]/i) {
    print qq{ok - 8 "궹"=~/[\$from-궺]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 8 "궹"=~/[\$from-궺]/i $^X $__FILE__\n};
}

if ("궺" =~ /[$from-궺]/i) {
    print qq{ok - 9 "궺"=~/[\$from-궺]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 9 "궺"=~/[\$from-궺]/i $^X $__FILE__\n};
}

if ("궻" !~ /[$from-궺]/i) {
    print qq{ok - 10 "궻"!~/[\$from-궺]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 10 "궻"!~/[\$from-궺]/i $^X $__FILE__\n};
}

my $to = '궺';
if ("궶" !~ /[$from-$to]/i) {
    print qq{ok - 11 "궶"!~/[\$from-\$to]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 11 "궶"!~/[\$from-\$to]/i $^X $__FILE__\n};
}

if ("궸" =~ /[$from-$to]/i) {
    print qq{ok - 12 "궸"=~/[\$from-\$to]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 12 "궸"=~/[\$from-\$to]/i $^X $__FILE__\n};
}

if ("궹" =~ /[$from-$to]/i) {
    print qq{ok - 13 "궹"=~/[\$from-\$to]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 13 "궹"=~/[\$from-\$to]/i $^X $__FILE__\n};
}

if ("궺" =~ /[$from-$to]/i) {
    print qq{ok - 14 "궺"=~/[\$from-\$to]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 14 "궺"=~/[\$from-\$to]/i $^X $__FILE__\n};
}

if ("궻" !~ /[$from-$to]/i) {
    print qq{ok - 15 "궻"!~/[\$from-\$to]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 15 "궻"!~/[\$from-\$to]/i $^X $__FILE__\n};
}

if ("궶" !~ /[${from}-${to}]/i) {
    print qq{ok - 16 "궶"!~/[\${from}-\${to}]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 16 "궶"!~/[\${from}-\${to}]/i $^X $__FILE__\n};
}

if ("궸" =~ /[${from}-${to}]/i) {
    print qq{ok - 17 "궸"=~/[\${from}-\${to}]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 17 "궸"=~/[\${from}-\${to}]/i $^X $__FILE__\n};
}

if ("궹" =~ /[${from}-${to}]/i) {
    print qq{ok - 18 "궹"=~/[\${from}-\${to}]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 18 "궹"=~/[\${from}-\${to}]/i $^X $__FILE__\n};
}

if ("궺" =~ /[${from}-${to}]/i) {
    print qq{ok - 19 "궺"=~/[\${from}-\${to}]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 19 "궺"=~/[\${from}-\${to}]/i $^X $__FILE__\n};
}

if ("궻" !~ /[${from}-${to}]/i) {
    print qq{ok - 20 "궻"!~/[\${from}-\${to}]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 20 "궻"!~/[\${from}-\${to}]/i $^X $__FILE__\n};
}

__END__
