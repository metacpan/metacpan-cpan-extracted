# encoding: Big5
# This file is encoded in Big5.
die "This file is not encoded in Big5.\n" if q{‚ } ne "\x82\xa0";

use Big5;
print "1..20\n";

my $__FILE__ = __FILE__;

if ("A" =~ /[B-‚Ë]/i) {
    print qq{ok - 1 "A"=~/[B-‚Ë]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 "A"=~/[B-‚Ë]/i $^X $__FILE__\n};
}

if ("B" =~ /[B-‚Ë]/i) {
    print qq{ok - 2 "B"=~/[B-‚Ë]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 "B"=~/[B-‚Ë]/i $^X $__FILE__\n};
}

if ("‚Ê" =~ /[B-‚Ë]/i) {
    print qq{ok - 3 "‚Ê"=~/[B-‚Ë]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 "‚Ê"=~/[B-‚Ë]/i $^X $__FILE__\n};
}

if ("‚Ë" =~ /[B-‚Ë]/i) {
    print qq{ok - 4 "‚Ë"=~/[B-‚Ë]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 "‚Ë"=~/[B-‚Ë]/i $^X $__FILE__\n};
}

if ("‚Ì" !~ /[B-‚Ë]/i) {
    print qq{ok - 5 "‚Ì"!~/[B-‚Ë]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 5 "‚Ì"!~/[B-‚Ë]/i $^X $__FILE__\n};
}

my $from = 'B';
if ("A" =~ /[$from-‚Ë]/i) {
    print qq{ok - 6 "A"=~/[\$from-‚Ë]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 6 "A"=~/[\$from-‚Ë]/i $^X $__FILE__\n};
}

if ("B" =~ /[$from-‚Ë]/i) {
    print qq{ok - 7 "B"=~/[\$from-‚Ë]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 7 "B"=~/[\$from-‚Ë]/i $^X $__FILE__\n};
}

if ("‚Ê" =~ /[$from-‚Ë]/i) {
    print qq{ok - 8 "‚Ê"=~/[\$from-‚Ë]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 8 "‚Ê"=~/[\$from-‚Ë]/i $^X $__FILE__\n};
}

if ("‚Ë" =~ /[$from-‚Ë]/i) {
    print qq{ok - 9 "‚Ë"=~/[\$from-‚Ë]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 9 "‚Ë"=~/[\$from-‚Ë]/i $^X $__FILE__\n};
}

if ("‚Ì" !~ /[$from-‚Ë]/i) {
    print qq{ok - 10 "‚Ì"!~/[\$from-‚Ë]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 10 "‚Ì"!~/[\$from-‚Ë]/i $^X $__FILE__\n};
}

my $to = '‚Ë';
if ("A" =~ /[$from-$to]/i) {
    print qq{ok - 11 "A"=~/[\$from-\$to]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 11 "A"=~/[\$from-\$to]/i $^X $__FILE__\n};
}

if ("B" =~ /[$from-$to]/i) {
    print qq{ok - 12 "B"=~/[\$from-\$to]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 12 "B"=~/[\$from-\$to]/i $^X $__FILE__\n};
}

if ("‚Ê" =~ /[$from-$to]/i) {
    print qq{ok - 13 "‚Ê"=~/[\$from-\$to]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 13 "‚Ê"=~/[\$from-\$to]/i $^X $__FILE__\n};
}

if ("‚Ë" =~ /[$from-$to]/i) {
    print qq{ok - 14 "‚Ë"=~/[\$from-\$to]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 14 "‚Ë"=~/[\$from-\$to]/i $^X $__FILE__\n};
}

if ("‚Ì" !~ /[$from-$to]/i) {
    print qq{ok - 15 "‚Ì"!~/[\$from-\$to]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 15 "‚Ì"!~/[\$from-\$to]/i $^X $__FILE__\n};
}

if ("A" =~ /[${from}-${to}]/i) {
    print qq{ok - 16 "A"=~/[\${from}-\${to}]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 16 "A"=~/[\${from}-\${to}]/i $^X $__FILE__\n};
}

if ("B" =~ /[${from}-${to}]/i) {
    print qq{ok - 17 "B"=~/[\${from}-\${to}]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 17 "B"=~/[\${from}-\${to}]/i $^X $__FILE__\n};
}

if ("‚Ê" =~ /[${from}-${to}]/i) {
    print qq{ok - 18 "‚Ê"=~/[\${from}-\${to}]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 18 "‚Ê"=~/[\${from}-\${to}]/i $^X $__FILE__\n};
}

if ("‚Ë" =~ /[${from}-${to}]/i) {
    print qq{ok - 19 "‚Ë"=~/[\${from}-\${to}]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 19 "‚Ë"=~/[\${from}-\${to}]/i $^X $__FILE__\n};
}

if ("‚Ì" !~ /[${from}-${to}]/i) {
    print qq{ok - 20 "‚Ì"!~/[\${from}-\${to}]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 20 "‚Ì"!~/[\${from}-\${to}]/i $^X $__FILE__\n};
}

__END__
