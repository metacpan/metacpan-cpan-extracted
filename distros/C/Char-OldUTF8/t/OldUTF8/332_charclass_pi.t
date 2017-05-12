# encoding: OldUTF8
# This file is encoded in old UTF-8.
die "This file is not encoded in old UTF-8.\n" if q{あ} ne "\xe3\x81\x82";

use OldUTF8;
print "1..20\n";

my $__FILE__ = __FILE__;

if ("な" !~ /[に-ね]/i) {
    print qq{ok - 1 "な"!~/[に-ね]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 "な"!~/[に-ね]/i $^X $__FILE__\n};
}

if ("に" =~ /[に-ね]/i) {
    print qq{ok - 2 "に"=~/[に-ね]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 "に"=~/[に-ね]/i $^X $__FILE__\n};
}

if ("ぬ" =~ /[に-ね]/i) {
    print qq{ok - 3 "ぬ"=~/[に-ね]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 "ぬ"=~/[に-ね]/i $^X $__FILE__\n};
}

if ("ね" =~ /[に-ね]/i) {
    print qq{ok - 4 "ね"=~/[に-ね]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 "ね"=~/[に-ね]/i $^X $__FILE__\n};
}

if ("の" !~ /[に-ね]/i) {
    print qq{ok - 5 "の"!~/[に-ね]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 5 "の"!~/[に-ね]/i $^X $__FILE__\n};
}

my $from = 'に';
if ("な" !~ /[$from-ね]/i) {
    print qq{ok - 6 "な"!~/[\$from-ね]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 6 "な"!~/[\$from-ね]/i $^X $__FILE__\n};
}

if ("に" =~ /[$from-ね]/i) {
    print qq{ok - 7 "に"=~/[\$from-ね]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 7 "に"=~/[\$from-ね]/i $^X $__FILE__\n};
}

if ("ぬ" =~ /[$from-ね]/i) {
    print qq{ok - 8 "ぬ"=~/[\$from-ね]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 8 "ぬ"=~/[\$from-ね]/i $^X $__FILE__\n};
}

if ("ね" =~ /[$from-ね]/i) {
    print qq{ok - 9 "ね"=~/[\$from-ね]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 9 "ね"=~/[\$from-ね]/i $^X $__FILE__\n};
}

if ("の" !~ /[$from-ね]/i) {
    print qq{ok - 10 "の"!~/[\$from-ね]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 10 "の"!~/[\$from-ね]/i $^X $__FILE__\n};
}

my $to = 'ね';
if ("な" !~ /[$from-$to]/i) {
    print qq{ok - 11 "な"!~/[\$from-\$to]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 11 "な"!~/[\$from-\$to]/i $^X $__FILE__\n};
}

if ("に" =~ /[$from-$to]/i) {
    print qq{ok - 12 "に"=~/[\$from-\$to]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 12 "に"=~/[\$from-\$to]/i $^X $__FILE__\n};
}

if ("ぬ" =~ /[$from-$to]/i) {
    print qq{ok - 13 "ぬ"=~/[\$from-\$to]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 13 "ぬ"=~/[\$from-\$to]/i $^X $__FILE__\n};
}

if ("ね" =~ /[$from-$to]/i) {
    print qq{ok - 14 "ね"=~/[\$from-\$to]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 14 "ね"=~/[\$from-\$to]/i $^X $__FILE__\n};
}

if ("の" !~ /[$from-$to]/i) {
    print qq{ok - 15 "の"!~/[\$from-\$to]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 15 "の"!~/[\$from-\$to]/i $^X $__FILE__\n};
}

if ("な" !~ /[${from}-${to}]/i) {
    print qq{ok - 16 "な"!~/[\${from}-\${to}]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 16 "な"!~/[\${from}-\${to}]/i $^X $__FILE__\n};
}

if ("に" =~ /[${from}-${to}]/i) {
    print qq{ok - 17 "に"=~/[\${from}-\${to}]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 17 "に"=~/[\${from}-\${to}]/i $^X $__FILE__\n};
}

if ("ぬ" =~ /[${from}-${to}]/i) {
    print qq{ok - 18 "ぬ"=~/[\${from}-\${to}]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 18 "ぬ"=~/[\${from}-\${to}]/i $^X $__FILE__\n};
}

if ("ね" =~ /[${from}-${to}]/i) {
    print qq{ok - 19 "ね"=~/[\${from}-\${to}]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 19 "ね"=~/[\${from}-\${to}]/i $^X $__FILE__\n};
}

if ("の" !~ /[${from}-${to}]/i) {
    print qq{ok - 20 "の"!~/[\${from}-\${to}]/i $^X $__FILE__\n};
}
else {
    print qq{not ok - 20 "の"!~/[\${from}-\${to}]/i $^X $__FILE__\n};
}

__END__
