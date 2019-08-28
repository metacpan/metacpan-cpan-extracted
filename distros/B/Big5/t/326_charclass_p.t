# encoding: Big5
# This file is encoded in Big5.
die "This file is not encoded in Big5.\n" if q{‚ } ne "\x82\xa0";

use Big5;
print "1..20\n";

my $__FILE__ = __FILE__;

if ("‚È" !~ /[‚É-‚Ë]/) {
    print qq{ok - 1 "‚È"!~/[‚É-‚Ë]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 "‚È"!~/[‚É-‚Ë]/ $^X $__FILE__\n};
}

if ("‚É" =~ /[‚É-‚Ë]/) {
    print qq{ok - 2 "‚É"=~/[‚É-‚Ë]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 "‚É"=~/[‚É-‚Ë]/ $^X $__FILE__\n};
}

if ("‚Ê" =~ /[‚É-‚Ë]/) {
    print qq{ok - 3 "‚Ê"=~/[‚É-‚Ë]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 "‚Ê"=~/[‚É-‚Ë]/ $^X $__FILE__\n};
}

if ("‚Ë" =~ /[‚É-‚Ë]/) {
    print qq{ok - 4 "‚Ë"=~/[‚É-‚Ë]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 "‚Ë"=~/[‚É-‚Ë]/ $^X $__FILE__\n};
}

if ("‚Ì" !~ /[‚É-‚Ë]/) {
    print qq{ok - 5 "‚Ì"!~/[‚É-‚Ë]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 5 "‚Ì"!~/[‚É-‚Ë]/ $^X $__FILE__\n};
}

my $from = '‚É';
if ("‚È" !~ /[$from-‚Ë]/) {
    print qq{ok - 6 "‚È"!~/[\$from-‚Ë]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 6 "‚È"!~/[\$from-‚Ë]/ $^X $__FILE__\n};
}

if ("‚É" =~ /[$from-‚Ë]/) {
    print qq{ok - 7 "‚É"=~/[\$from-‚Ë]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 7 "‚É"=~/[\$from-‚Ë]/ $^X $__FILE__\n};
}

if ("‚Ê" =~ /[$from-‚Ë]/) {
    print qq{ok - 8 "‚Ê"=~/[\$from-‚Ë]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 8 "‚Ê"=~/[\$from-‚Ë]/ $^X $__FILE__\n};
}

if ("‚Ë" =~ /[$from-‚Ë]/) {
    print qq{ok - 9 "‚Ë"=~/[\$from-‚Ë]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 9 "‚Ë"=~/[\$from-‚Ë]/ $^X $__FILE__\n};
}

if ("‚Ì" !~ /[$from-‚Ë]/) {
    print qq{ok - 10 "‚Ì"!~/[\$from-‚Ë]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 10 "‚Ì"!~/[\$from-‚Ë]/ $^X $__FILE__\n};
}

my $to = '‚Ë';
if ("‚È" !~ /[$from-$to]/) {
    print qq{ok - 11 "‚È"!~/[\$from-\$to]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 11 "‚È"!~/[\$from-\$to]/ $^X $__FILE__\n};
}

if ("‚É" =~ /[$from-$to]/) {
    print qq{ok - 12 "‚É"=~/[\$from-\$to]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 12 "‚É"=~/[\$from-\$to]/ $^X $__FILE__\n};
}

if ("‚Ê" =~ /[$from-$to]/) {
    print qq{ok - 13 "‚Ê"=~/[\$from-\$to]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 13 "‚Ê"=~/[\$from-\$to]/ $^X $__FILE__\n};
}

if ("‚Ë" =~ /[$from-$to]/) {
    print qq{ok - 14 "‚Ë"=~/[\$from-\$to]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 14 "‚Ë"=~/[\$from-\$to]/ $^X $__FILE__\n};
}

if ("‚Ì" !~ /[$from-$to]/) {
    print qq{ok - 15 "‚Ì"!~/[\$from-\$to]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 15 "‚Ì"!~/[\$from-\$to]/ $^X $__FILE__\n};
}

if ("‚È" !~ /[${from}-${to}]/) {
    print qq{ok - 16 "‚È"!~/[\${from}-\${to}]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 16 "‚È"!~/[\${from}-\${to}]/ $^X $__FILE__\n};
}

if ("‚É" =~ /[${from}-${to}]/) {
    print qq{ok - 17 "‚É"=~/[\${from}-\${to}]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 17 "‚É"=~/[\${from}-\${to}]/ $^X $__FILE__\n};
}

if ("‚Ê" =~ /[${from}-${to}]/) {
    print qq{ok - 18 "‚Ê"=~/[\${from}-\${to}]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 18 "‚Ê"=~/[\${from}-\${to}]/ $^X $__FILE__\n};
}

if ("‚Ë" =~ /[${from}-${to}]/) {
    print qq{ok - 19 "‚Ë"=~/[\${from}-\${to}]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 19 "‚Ë"=~/[\${from}-\${to}]/ $^X $__FILE__\n};
}

if ("‚Ì" !~ /[${from}-${to}]/) {
    print qq{ok - 20 "‚Ì"!~/[\${from}-\${to}]/ $^X $__FILE__\n};
}
else {
    print qq{not ok - 20 "‚Ì"!~/[\${from}-\${to}]/ $^X $__FILE__\n};
}

__END__
