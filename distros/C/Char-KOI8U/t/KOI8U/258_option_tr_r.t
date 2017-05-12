# encoding: KOI8U
# This file is encoded in KOI8-U.
die "This file is not encoded in KOI8-U.\n" if q{‚ } ne "\x82\xa0";

use strict;
use KOI8U;
print "1..6\n";

my $__FILE__ = __FILE__;

# tr///r
$_ = 'ABCDEF';
my $r = tr/ABC/XYZ/r;
if ($_ eq 'ABCDEF') {
    print qq{ok - 1 tr/ABC/XYZ/, \$_ eq 'ABCDEF' $^X $__FILE__\n};
}
else {
    print qq{not ok - 1 tr/ABC/XYZ/, \$_ eq 'ABCDEF' $^X $__FILE__\n};
}
if ($r eq 'XYZDEF') {
    print qq{ok - 2 tr/ABC/XYZ/, \$r eq 'XYZDEF' $^X $__FILE__\n};
}
else {
    print qq{not ok - 2 tr/ABC/XYZ/, \$r eq 'XYZDEF' $^X $__FILE__\n};
}

# $var =~ tr///r
my $var = 'ABCDEF';
$r = $var =~ tr/ABC/XYZ/r;
if ($var eq 'ABCDEF') {
    print qq{ok - 3 tr/ABC/XYZ/, \$var eq 'ABCDEF' $^X $__FILE__\n};
}
else {
    print qq{not ok - 3 tr/ABC/XYZ/, \$var eq 'ABCDEF' $^X $__FILE__\n};
}
if ($r eq 'XYZDEF') {
    print qq{ok - 4 tr/ABC/XYZ/, \$r eq 'XYZDEF' $^X $__FILE__\n};
}
else {
    print qq{not ok - 4 tr/ABC/XYZ/, \$r eq 'XYZDEF' $^X $__FILE__\n};
}

# @r = map { tr///r } @_;
@_ = ('ABCDEF','ABCGHI','ABCJKL');
my @r = map { tr/ABC/XYZ/r; } @_;
if (join(' ',@_) eq 'ABCDEF ABCGHI ABCJKL') {
    print qq{ok - 5 map { tr/ABC/XYZ/r; }, join(' ',\@_) eq 'ABCDEF ABCGHI ABCJKL' $^X $__FILE__\n};
}
else {
    print qq{not ok - 5 map { tr/ABC/XYZ/r; }, join(' ',\@_) eq 'ABCDEF ABCGHI ABCJKL' $^X $__FILE__\n};
}
if (join(' ',@r) eq 'XYZDEF XYZGHI XYZJKL') {
    print qq{ok - 6 map { tr/ABC/XYZ/r; }, join(' ',\@r) eq 'XYZDEF XYZGHI XYZJKL' $^X $__FILE__\n};
}
else {
    print qq{not ok - 6 map { tr/ABC/XYZ/r; }, join(' ',\@r) eq 'XYZDEF XYZGHI XYZJKL' $^X $__FILE__\n};
}

__END__
