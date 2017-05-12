# encoding: EUCJP
# This file is encoded in EUC-JP.
die "This file is not encoded in EUC-JP.\n" if q{あ} ne "\xa4\xa2";

use EUCJP;
print "1..20\n";

my $__FILE__ = __FILE__;

if ("な" =~ /[^に-ね]/) {
    print qq{ok - 1 "な"=~/[^に-ね]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 "な"=~/[^に-ね]/ $^X $__FILE__\n};
}

if ("に" !~ /[^に-ね]/) {
    print qq{ok - 2 "に"!~/[^に-ね]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 "に"!~/[^に-ね]/ $^X $__FILE__\n};
}

if ("ぬ" !~ /[^に-ね]/) {
    print qq{ok - 3 "ぬ"!~/[^に-ね]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 "ぬ"!~/[^に-ね]/ $^X $__FILE__\n};
}

if ("ね" !~ /[^に-ね]/) {
    print qq{ok - 4 "ね"!~/[^に-ね]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 "ね"!~/[^に-ね]/ $^X $__FILE__\n};
}

if ("の" =~ /[^に-ね]/) {
    print qq{ok - 5 "の"=~/[^に-ね]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 5 "の"=~/[^に-ね]/ $^X $__FILE__\n};
}

my $from = 'に';
if ("な" =~ /[^$from-ね]/) {
    print qq{ok - 6 "な"=~/[^\$from-ね]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 6 "な"=~/[^\$from-ね]/ $^X $__FILE__\n};
}

if ("に" !~ /[^$from-ね]/) {
    print qq{ok - 7 "に"!~/[^\$from-ね]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 7 "に"!~/[^\$from-ね]/ $^X $__FILE__\n};
}

if ("ぬ" !~ /[^$from-ね]/) {
    print qq{ok - 8 "ぬ"!~/[^\$from-ね]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 8 "ぬ"!~/[^\$from-ね]/ $^X $__FILE__\n};
}

if ("ね" !~ /[^$from-ね]/) {
    print qq{ok - 9 "ね"!~/[^\$from-ね]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 9 "ね"!~/[^\$from-ね]/ $^X $__FILE__\n};
}

if ("の" =~ /[^$from-ね]/) {
    print qq{ok - 10 "の"=~/[^\$from-ね]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 10 "の"=~/[^\$from-ね]/ $^X $__FILE__\n};
}

my $to = 'ね';
if ("な" =~ /[^$from-$to]/) {
    print qq{ok - 11 "な"=~/[^\$from-\$to]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 11 "な"=~/[^\$from-\$to]/ $^X $__FILE__\n};
}

if ("に" !~ /[^$from-$to]/) {
    print qq{ok - 12 "に"!~/[^\$from-\$to]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 12 "に"!~/[^\$from-\$to]/ $^X $__FILE__\n};
}

if ("ぬ" !~ /[^$from-$to]/) {
    print qq{ok - 13 "ぬ"!~/[^\$from-\$to]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 13 "ぬ"!~/[^\$from-\$to]/ $^X $__FILE__\n};
}

if ("ね" !~ /[^$from-$to]/) {
    print qq{ok - 14 "ね"!~/[^\$from-\$to]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 14 "ね"!~/[^\$from-\$to]/ $^X $__FILE__\n};
}

if ("の" =~ /[^$from-$to]/) {
    print qq{ok - 15 "の"=~/[^\$from-\$to]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 15 "の"=~/[^\$from-\$to]/ $^X $__FILE__\n};
}

if ("な" =~ /[^${from}-${to}]/) {
    print qq{ok - 16 "な"=~/[^\${from}-\${to}]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 16 "な"=~/[^\${from}-\${to}]/ $^X $__FILE__\n};
}

if ("に" !~ /[^${from}-${to}]/) {
    print qq{ok - 17 "に"!~/[^\${from}-\${to}]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 17 "に"!~/[^\${from}-\${to}]/ $^X $__FILE__\n};
}

if ("ぬ" !~ /[^${from}-${to}]/) {
    print qq{ok - 18 "ぬ"!~/[^\${from}-\${to}]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 18 "ぬ"!~/[^\${from}-\${to}]/ $^X $__FILE__\n};
}

if ("ね" !~ /[^${from}-${to}]/) {
    print qq{ok - 19 "ね"!~/[^\${from}-\${to}]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 19 "ね"!~/[^\${from}-\${to}]/ $^X $__FILE__\n};
}

if ("の" =~ /[^${from}-${to}]/) {
    print qq{ok - 20 "の"=~/[^\${from}-\${to}]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 20 "の"=~/[^\${from}-\${to}]/ $^X $__FILE__\n};
}

__END__
