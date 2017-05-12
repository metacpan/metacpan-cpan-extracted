# encoding: EUCJP
# This file is encoded in EUC-JP.
die "This file is not encoded in EUC-JP.\n" if q{あ} ne "\xa4\xa2";

use EUCJP;
print "1..20\n";

my $__FILE__ = __FILE__;

if ("A" !~ /[B-ね]/) {
    print qq{ok - 1 "A"!~/[B-ね]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 "A"!~/[B-ね]/ $^X $__FILE__\n};
}

if ("B" =~ /[B-ね]/) {
    print qq{ok - 2 "B"=~/[B-ね]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 "B"=~/[B-ね]/ $^X $__FILE__\n};
}

if ("ぬ" =~ /[B-ね]/) {
    print qq{ok - 3 "ぬ"=~/[B-ね]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 "ぬ"=~/[B-ね]/ $^X $__FILE__\n};
}

if ("ね" =~ /[B-ね]/) {
    print qq{ok - 4 "ね"=~/[B-ね]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 "ね"=~/[B-ね]/ $^X $__FILE__\n};
}

if ("の" !~ /[B-ね]/) {
    print qq{ok - 5 "の"!~/[B-ね]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 5 "の"!~/[B-ね]/ $^X $__FILE__\n};
}

my $from = 'B';
if ("A" !~ /[$from-ね]/) {
    print qq{ok - 6 "A"!~/[\$from-ね]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 6 "A"!~/[\$from-ね]/ $^X $__FILE__\n};
}

if ("B" =~ /[$from-ね]/) {
    print qq{ok - 7 "B"=~/[\$from-ね]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 7 "B"=~/[\$from-ね]/ $^X $__FILE__\n};
}

if ("ぬ" =~ /[$from-ね]/) {
    print qq{ok - 8 "ぬ"=~/[\$from-ね]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 8 "ぬ"=~/[\$from-ね]/ $^X $__FILE__\n};
}

if ("ね" =~ /[$from-ね]/) {
    print qq{ok - 9 "ね"=~/[\$from-ね]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 9 "ね"=~/[\$from-ね]/ $^X $__FILE__\n};
}

if ("の" !~ /[$from-ね]/) {
    print qq{ok - 10 "の"!~/[\$from-ね]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 10 "の"!~/[\$from-ね]/ $^X $__FILE__\n};
}

my $to = 'ね';
if ("A" !~ /[$from-$to]/) {
    print qq{ok - 11 "A"!~/[\$from-\$to]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 11 "A"!~/[\$from-\$to]/ $^X $__FILE__\n};
}

if ("B" =~ /[$from-$to]/) {
    print qq{ok - 12 "B"=~/[\$from-\$to]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 12 "B"=~/[\$from-\$to]/ $^X $__FILE__\n};
}

if ("ぬ" =~ /[$from-$to]/) {
    print qq{ok - 13 "ぬ"=~/[\$from-\$to]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 13 "ぬ"=~/[\$from-\$to]/ $^X $__FILE__\n};
}

if ("ね" =~ /[$from-$to]/) {
    print qq{ok - 14 "ね"=~/[\$from-\$to]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 14 "ね"=~/[\$from-\$to]/ $^X $__FILE__\n};
}

if ("の" !~ /[$from-$to]/) {
    print qq{ok - 15 "の"!~/[\$from-\$to]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 15 "の"!~/[\$from-\$to]/ $^X $__FILE__\n};
}

if ("A" !~ /[${from}-${to}]/) {
    print qq{ok - 16 "A"!~/[\${from}-\${to}]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 16 "A"!~/[\${from}-\${to}]/ $^X $__FILE__\n};
}

if ("B" =~ /[${from}-${to}]/) {
    print qq{ok - 17 "B"=~/[\${from}-\${to}]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 17 "B"=~/[\${from}-\${to}]/ $^X $__FILE__\n};
}

if ("ぬ" =~ /[${from}-${to}]/) {
    print qq{ok - 18 "ぬ"=~/[\${from}-\${to}]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 18 "ぬ"=~/[\${from}-\${to}]/ $^X $__FILE__\n};
}

if ("ね" =~ /[${from}-${to}]/) {
    print qq{ok - 19 "ね"=~/[\${from}-\${to}]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 19 "ね"=~/[\${from}-\${to}]/ $^X $__FILE__\n};
}

if ("の" !~ /[${from}-${to}]/) {
    print qq{ok - 20 "の"!~/[\${from}-\${to}]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 20 "の"!~/[\${from}-\${to}]/ $^X $__FILE__\n};
}

__END__
