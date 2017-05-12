#!/usr/bin/perl
#
# Takes from STDIN a text file with fortune format but with duplicate phrases,
# and produces on STDOUT only the unique phrases, in the same order
#
# $Id: $
#
use strict;
use warnings;

my %phrases;
my $current;
my $line;

while( <STDIN> )
{
    $line = $_;

    if($line =~ /^\%/)
    {
        if(! exists $phrases{$current})
        {
            print $current, '%', "\n";
            $phrases{$current} = 0;
        }
        $current = '';
    }
    else
    {
        $current .= $line;
    }
}

