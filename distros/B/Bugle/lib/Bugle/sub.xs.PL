#!perl -w

open my $fh, '>', $ARGV[0] or die "$ARGV[0]: $!";
print $fh $_ while <DATA>;

__END__
/*

=head1 NAME

Bugle::sub - test of .xs.PL indexing

*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
MODULE = Bugle::sub       PACKAGE = Bugle::sub
PROTOTYPES: DISABLE
int
is_even(input)
       int     input
   CODE:
       RETVAL = (input % 2 == 0);
   OUTPUT:
       RETVAL
