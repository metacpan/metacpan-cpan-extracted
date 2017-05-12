# encoding: Latin3
# This file is encoded in Latin-3.
die "This file is not encoded in Latin-3.\n" if q{ } ne "\x82\xa0";

use strict;
use Latin3;
print "1..16\n";

my $__FILE__ = __FILE__;

# without /g, match, scalar
my $var1 = 'ABCDEF';
my $rep1 = $var1 =~ s/CD/XY/r;
if ($var1 eq 'ABCDEF') {
    print qq{ok - 1 s/CD/XY/r, \$var1 eq 'ABCDEF' $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 s/CD/XY/r, \$var1 eq 'ABCDEF' $^X $__FILE__\n};
}
if ($rep1 eq 'ABXYEF') {
    print qq{ok - 2 s/CD/XY/r, \$rep1 eq 'ABXYEF' $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 s/CD/XY/r, \$rep1 eq 'ABXYEF' $^X $__FILE__\n};
}

# without /g, match, list
my $var2 = 'ABCDEF';
my @rep2 = $var2 =~ s/CD/XY/r;
if ($var2 eq 'ABCDEF') {
    print qq{ok - 3 s/CD/XY/r, \$var2 eq 'ABCDEF' $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 s/CD/XY/r, \$var2 eq 'ABCDEF' $^X $__FILE__\n};
}
if (join('',@rep2) eq 'ABXYEF') {
    print qq{ok - 4 s/CD/XY/r, join('',\@rep2) eq 'ABXYEF' $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 s/CD/XY/r, join('',\@rep2) eq 'ABXYEF' $^X $__FILE__\n};
}

# without /g, not match, scalar
my $var3 = 'ABCDEF';
my $rep3 = $var3 =~ s/GH/XY/r;
if ($var3 eq 'ABCDEF') {
    print qq{ok - 5 s/GH/XY/r, \$var3 eq 'ABCDEF' $^X $__FILE__\n};
}
else {
    print qq{not ok - 5 s/GH/XY/r, \$var3 eq 'ABCDEF' $^X $__FILE__\n};
}
if ($rep3 eq 'ABCDEF') {
    print qq{ok - 6 s/GH/XY/r, \$rep3 eq 'ABCDEF' $^X $__FILE__\n};
}
else {
    print qq{not ok - 6 s/GH/XY/r, \$rep3 eq 'ABCDEF' $^X $__FILE__\n};
}

# without /g, not match, list
my $var4 = 'ABCDEF';
my @rep4 = $var4 =~ s/GH/XY/r;
if ($var4 eq 'ABCDEF') {
    print qq{ok - 7 s/GH/XY/r, \$var4 eq 'ABCDEF' $^X $__FILE__\n};
}
else {
    print qq{not ok - 7 s/GH/XY/r, \$var4 eq 'ABCDEF' $^X $__FILE__\n};
}
if (join('',@rep4) eq 'ABCDEF') {
    print qq{ok - 8 s/GH/XY/r, join('',\@rep4) eq 'ABCDEF' $^X $__FILE__\n};
}
else {
    print qq{not ok - 8 s/GH/XY/r, join('',\@rep4) eq 'ABCDEF' $^X $__FILE__\n};
}

# with /g, match, scalar
my $var5 = 'ABCDEFABCDEFABCDEF';
my $rep5 = $var5 =~ s/CD/XY/gr;
if ($var5 eq 'ABCDEFABCDEFABCDEF') {
    print qq{ok - 9 s/CD/XY/gr, \$var5 eq 'ABCDEFABCDEFABCDEF' $^X $__FILE__\n};
}
else {
    print qq{not ok - 9 s/CD/XY/gr, \$var5 eq 'ABCDEFABCDEFABCDEF' $^X $__FILE__\n};
}
if ($rep5 eq 'ABXYEFABXYEFABXYEF') {
    print qq{ok - 10 s/CD/XY/gr, \$rep5 eq 'ABXYEFABXYEFABXYEF' $^X $__FILE__\n};
}
else {
    print qq{not ok - 10 s/CD/XY/gr, \$rep5 eq 'ABXYEFABXYEFABXYEF' $^X $__FILE__\n};
}

# with /g, match, list
my $var6 = 'ABCDEFABCDEFABCDEF';
my @rep6 = $var6 =~ s/CD/XY/gr;
if ($var6 eq 'ABCDEFABCDEFABCDEF') {
    print qq{ok - 11 s/CD/XY/gr, \$var6 eq 'ABCDEFABCDEFABCDEF' $^X $__FILE__\n};
}
else {
    print qq{not ok - 11 s/CD/XY/gr, \$var6 eq 'ABCDEFABCDEFABCDEF' $^X $__FILE__\n};
}
if (join('',@rep6) eq 'ABXYEFABXYEFABXYEF') {
    print qq{ok - 12 s/CD/XY/gr, join('',\@rep6) eq 'ABXYEFABXYEFABXYEF' $^X $__FILE__\n};
}
else {
    print qq{not ok - 12 s/CD/XY/gr, join('',\@rep6) eq 'ABXYEFABXYEFABXYEF' $^X $__FILE__\n};
}

# with /g, not match, scalar
my $var7 = 'ABCDEFABCDEFABCDEF';
my $rep7 = $var7 =~ s/GH/XY/gr;
if ($var7 eq 'ABCDEFABCDEFABCDEF') {
    print qq{ok - 13 s/GH/XY/gr, \$var7 eq 'ABCDEFABCDEFABCDEF' $^X $__FILE__\n};
}
else {
    print qq{not ok - 13 s/GH/XY/gr, \$var7 eq 'ABCDEFABCDEFABCDEF' $^X $__FILE__\n};
}
if ($rep7 eq 'ABCDEFABCDEFABCDEF') {
    print qq{ok - 14 s/GH/XY/gr, \$rep7 eq 'ABCDEFABCDEFABCDEF' $^X $__FILE__\n};
}
else {
    print qq{not ok - 14 s/GH/XY/gr, \$rep7 eq 'ABCDEFABCDEFABCDEF' $^X $__FILE__\n};
}

# with /g, not match, list
my $var8 = 'ABCDEFABCDEFABCDEF';
my @rep8 = $var8 =~ s/GH/XY/gr;
if ($var8 eq 'ABCDEFABCDEFABCDEF') {
    print qq{ok - 15 s/GH/XY/gr, \$var8 eq 'ABCDEFABCDEFABCDEF' $^X $__FILE__\n};
}
else {
    print qq{not ok - 15 s/GH/XY/gr, \$var8 eq 'ABCDEFABCDEFABCDEF' $^X $__FILE__\n};
}
if (join('',@rep8) eq 'ABCDEFABCDEFABCDEF') {
    print qq{ok - 16 s/GH/XY/gr, join('',\@rep8) eq 'ABCDEFABCDEFABCDEF' $^X $__FILE__\n};
}
else {
    print qq{not ok - 16 s/GH/XY/gr, join('',\@rep8) eq 'ABCDEFABCDEFABCDEF' $^X $__FILE__\n};
}

__END__
