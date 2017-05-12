#!/usr/bin/perl

use strict;
use warnings;

use Acme::Gosub;

my @japh = ("Just another", " Perl", " and Acme::Gosub", " Hacker\n");

sub print_japh
{
    my $print_me;
    $print_me = $japh[0];
    gosub PRINT;
    $print_me = $japh[1];
    gosub PRINT;
    $print_me = $japh[2];
    gosub PRINT;
    $print_me = $japh[3];
    gosub PRINT;
    return;
    PRINT:
    print $print_me;
    greturn;
}
print_japh();

