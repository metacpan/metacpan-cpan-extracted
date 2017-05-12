#!/usr/bin/perl -w
use strict;
use Data::Dumper;

use lib "../lib";
use Compress::BraceExpansion;

my %alphabet = ( 1 => 'a',   2 => 'b',  3 => 'c',  4 => 'd',  5 => 'e',  6 => 'f',
                 7 => 'g',   8 => 'h',  9 => 'i', 10 => 'j', 11 => 'k', 12 => 'l',
                 13 => 'm', 14 => 'n', 15 => 'o', 16 => 'p', 17 => 'q', 18 => 'r',
                 19 => 's', 20 => 't', 21 => 'u', 22 => 'v', 23 => 'w', 24 => 'x',
                 25 => 'y', 26 => 'z',
                 );

my $success = 0;
my $failed  = 0;
my $overall_percent_reduced = 0;

for my $test ( 0 .. 999 ) {
    my $string = get_random_string();
    next unless $string;
    my $expanded = expand( $string );
    unless ( $expanded ) {
        print "Failed to expand string $string\n";
        next;
    }


    my @expanded = split /\s+/, $expanded;
    my $reverse = Compress::BraceExpansion::shrink( @expanded );
    #my $reverse = `./brace-compress.pl $expanded`;
    #chomp $reverse;
    my $reexpanded = expand( $reverse );

    if ( $expanded eq $reexpanded ) {
        my $exp_length = length( $expanded );
        my $rev_length = length( $reverse );
        my $reduced_percent = int( $rev_length / $exp_length * 100 );
        $overall_percent_reduced += $reduced_percent;
        #print "SUCCESS: Reduced expansion of $string by $reduced_percent%\n";
        #print "\t$string => $expanded => $reverse\n";
        $success++;
    }
    else {
        print "FAILED:\n";
        print Dumper { $string => $expanded, $reverse => $reexpanded };
        $failed++;
    }
}

print "SUCCESS:$success FAILED:$failed\n";
print "PERCENT:", $overall_percent_reduced / $success, "\n";


#
#_* Subroutines
#

sub expand {
    my ( $string ) = @_;

    my $output = `bash -c \"echo $string\"`;
    chomp $output;

    my @matches = sort split /\s+/, $output;
    $output = join " ", sort @matches;
    my %uniq;
    @uniq{ @matches } = @matches;
    my @uniq_keys = sort keys %uniq;
    return unless @uniq_keys == @matches;

    return $output;

}

sub get_random_string {
    my $string;
    my $max_length = 40;
    my $length = (int rand 5 ) + 5;
    #$length += 5;
    for my $pos ( 0 .. $length ) {

        my $branch_chance = int rand 4;
        if ( $branch_chance == 1 ) {
            $string .= get_random_branch();
        }
        else {
            $string .= get_random_bit();
        }
        last if length( $string ) > $max_length;
    }

    return $string;
}

sub get_random_bit {
    my $string;

    my $char = int rand 25;
    $char++;
    return $alphabet{ $char };
    print "BIT: $string\n";

    return $string;
}

sub get_random_branch {
    my $string = "{";

    my $bits = int rand 5 + 1;

    my %bits;
    for my $bit ( 0 .. $bits ) {
        my $bit_string;

        # tasks - test cases with inner branches - note that the shell
        # does not properly handle some of these cases!
        #my $chance_innerbranch = int rand 10;
        #if ( $chance_innerbranch == 1 ) {
        #    $bit_string = get_random_branch()
        #}
        #else {
        for my $bit_length ( 0 .. int rand 10 ) {
            $bit_string .= get_random_bit();
        }
        #}
        $bits{$bit_string} = 1;
    }
    $string .= join ",", sort keys %bits;

    $string .= "}";
    return $string;
}
