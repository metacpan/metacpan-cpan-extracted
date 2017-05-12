#!/usr/bin/perl -l
# Will sort command-line arguments alphabetically except that integers
# (represented by a sequence of 9 or fewer consecutive digits) anywhere
# in the strings are sorted in numeric order relative to each other.

# The first version doesn't correctly sort integers with leading zeros.

# Both versions output extra digits if
# given a sequence of 10 or more digits.

use Algorithm::Loops qw( Filter );

@ARGV= split ' ', <DATA>
    if  ! @ARGV;

print join " ", Filter {
    s/\d(\d+)/$1/g
} sort
&Filter( sub {
    s/(\d+)/length($1).$1/ge
}, @ARGV );

print join " ", Filter {
    s/\d(\d+)=(0*)=/$2$1/g
} sort
&Filter( sub {
    s/(0*)(\d+)/length($2)."$2=$1="/ge
}, @ARGV );

__END__
m5 m45 m345 m05 m004 m0035 n2 l8
