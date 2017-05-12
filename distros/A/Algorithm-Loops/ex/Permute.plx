#!/usr/bin/perl -w
use strict;

use Algorithm::Loops qw( NextPermute NextPermuteNum );

Main( @ARGV );
exit 0;


sub Main {
    my @tokens= @_;
    my $noSort= 0;
    my $numComp= 0;
    while(  1 < @tokens  &&  $tokens[0] =~ /^-[^-]/  ) {
        ( my $flag= shift @tokens ) =~ s/^-//;
        while(  '' ne $flag  ) {
            if(  $flag =~ s/^s//  ) {
                $noSort= 1;
            } elsif(  $flag =~ s/^n//  ) {
                $numComp= 1;
            } else {
                die "$0: Unknown command-line option (-$flag).\n";
            }
        }
    }
    if(  0 == @tokens  ) {
        die "Usage: $0 [-s] word\n",
            "   or: $0 [-sn] t o k e n s\n",
            "Prints all unique permutations of the letters or words given.\n",
            "-s prevents the initial sorting of the letters/words.\n",
            "-n compares words as numbers.\n";
    } elsif(  1 == @tokens  ) {
        @tokens= $tokens[0] =~ /(.)/gs;
        $"= "";
    }

    #Sample use:
    my $cnt= 0;

    if(  $noSort  ) {

        if(  $numComp  ) {
            undef &NextPermute;
            *NextPermute= \&NextPermuteNum;
        }

        my $start= "@tokens";
        do {
            print ++$cnt, ": @tokens\n";
            NextPermute(@tokens);
        } while(  $start ne "@tokens"  );

    } elsif(  $numComp  ) {

        @tokens= sort {$a<=>$b} @tokens;
        do {
            print ++$cnt, ": @tokens\n";
        } while(  NextPermuteNum(@tokens)  );

    } else {

        @tokens= sort @tokens;
        do {
            print ++$cnt, ": @tokens\n";
        } while(  NextPermute(@tokens)  );

    }
}
