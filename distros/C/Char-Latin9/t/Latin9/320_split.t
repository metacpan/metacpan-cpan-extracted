# encoding: Latin9
# This file is encoded in Latin-9.
die "This file is not encoded in Latin-9.\n" if q{ } ne "\x82\xa0";

use Latin9;
print "1..12\n";

my $__FILE__ = __FILE__;
local $^W = 0;

my @split1 = split(/ */, "hi there");
my $join1 = join(":" => @split1);
if ($join1 eq 'h:i:t:h:e:r:e') {
    print qq{ok - 1 $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 ($join1) $^X $__FILE__\n};
}

my @split2 = split(/([-,])/, "1-10,20");
my $join2 = join("!" => @split2);
if ($join2 eq "1!-!10!,!20") {
    print qq{ok - 2 $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 ($join2) $^X $__FILE__\n};
}

my @split3 = split(/(-)|(,)/, "1-10,20");
my $join3 = join("!" => @split3);
if ($join3 eq "1!-!!10!!,!20") {
    print qq{ok - 3 $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 ($join3) $^X $__FILE__\n};
}

my @split4 = split(/(-(?#minus))(?#or)|(,)(?#comma)/, "1-10,20");
my $join4 = join("!" => @split4);
if ($join4 eq "1!-!!10!!,!20") {
    print qq{ok - 4 $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 ($join4) $^X $__FILE__\n};
}

my @split5 = split(/(-)|(,)|(\()/, "1-10,20(30");
my $join5 = join("!" => @split5);
if ($join5 eq "1!-!!!10!!,!!20!!!(!30") {
    print qq{ok - 5 $^X $__FILE__\n};
}
else {
    print qq{not ok - 5 ($join5) $^X $__FILE__\n};
}

my @split6 = split(/(-)|(,)|([\(])/, "1-10,20(30");
my $join6 = join("!" => @split6);
if ($join6 eq "1!-!!!10!!,!!20!!!(!30") {
    print qq{ok - 6 $^X $__FILE__\n};
}
else {
    print qq{not ok - 6 ($join6) $^X $__FILE__\n};
}

my @split7 = split(/(?:(-)|(,))/, "1-10,20");
my $join7 = join("!" => @split7);
if ($join7 eq "1!-!!10!!,!20") {
    print qq{ok - 7 $^X $__FILE__\n};
}
else {
    print qq{not ok - 7 ($join7) $^X $__FILE__\n};
}

my @split8 = split(/(-(?#minus))(?#or)|(,)(?#comma)/x, "1-10,20");
my $join8 = join("!" => @split8);
if ($join8 eq "1!-!!10!!,!20") {
    print qq{ok - 8 $^X $__FILE__\n};
}
else {
    print qq{not ok - 8 ($join8) $^X $__FILE__\n};
}

my @split9 = split(/(-)|(,)|(\()/x, "1-10,20(30");
my $join9 = join("!" => @split9);
if ($join9 eq "1!-!!!10!!,!!20!!!(!30") {
    print qq{ok - 9 $^X $__FILE__\n};
}
else {
    print qq{not ok - 9 ($join9) $^X $__FILE__\n};
}

my @split10 = split(/(-)|(,)|([\(])/x, "1-10,20(30");
my $join10 = join("!" => @split10);
if ($join10 eq "1!-!!!10!!,!!20!!!(!30") {
    print qq{ok - 10 $^X $__FILE__\n};
}
else {
    print qq{not ok - 10 ($join10) $^X $__FILE__\n};
}

my @split11 = split(/(?:(-)|(,))/x, "1-10,20");
my $join11 = join("!" => @split11);
if ($join11 eq "1!-!!10!!,!20") {
    print qq{ok - 11 $^X $__FILE__\n};
}
else {
    print qq{not ok - 11 ($join11) $^X $__FILE__\n};
}

my @split12 = split(/
    (-) | # minus
    (,)   # comma
    /x, "1-10,20");
my $join12 = join("!" => @split12);
if ($join12 eq "1!-!!10!!,!20") {
    print qq{ok - 12 $^X $__FILE__\n};
}
else {
    print qq{not ok - 12 ($join12) $^X $__FILE__\n};
}

__END__
