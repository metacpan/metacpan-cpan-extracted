#!/home/ben/software/install/bin/perl
use warnings;
use strict;

# Print all the comments in a C program:
my $c = <<EOF;
/* This is the main program. */
int main ()
{
    int i;
    /* Increment i by 1. */
    i++;
    // Now exit with zero status.
    return 0;
}
EOF
use C::Tokenize '$comment_re';
while ($c =~ /($comment_re)/g) {
    print "$1\n";
}

