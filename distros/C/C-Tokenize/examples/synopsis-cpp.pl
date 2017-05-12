#!/home/ben/software/install/bin/perl
use warnings;
use strict;
# Remove all C preprocessor instructions from a C program:
my $c = <<EOF;
#define X Y
#ifdef X
int X;
#endif
EOF
use C::Tokenize '$cpp_re';
$c =~ s/$cpp_re//g;
print "$c\n";

