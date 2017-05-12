package Benchmark::Perl::Formance::Plugin::PerlStone2015::fasta;
our $AUTHORITY = 'cpan:SCHWIGON';
# ABSTRACT: benchmark - Generate and write random DNA sequences
$Benchmark::Perl::Formance::Plugin::PerlStone2015::fasta::VERSION = '0.002';
# COMMAND LINE:
# /usr/bin/perl fasta.perl-4.perl 25000000

# The Computer Language Benchmarks game
# http://shootout.alioth.debian.org/
#
# contributed by David Pyke
# tweaked by Danny Sauer
# optimized by Steffen Mueller
# tweaked by Kuang-che Wu
# Benchmark::Perl::Formance plugin by Steffen Schwigon

use strict;
use warnings;

#############################################################
#                                                           #
# Benchmark Code ahead - Don't touch without strong reason! #
#                                                           #
#############################################################

use Benchmark ':hireswallclock';

our $PRINT = 0;

use constant IM => 139968;
use constant IA => 3877;
use constant IC => 29573;

use constant LINELENGTH => 60;

my $LAST = 42;
sub gen_random {
    return map {( ($_[0] * ($LAST = ($LAST * IA + IC) % IM)) / IM )} 1..($_[1]||1);
}

sub makeCumulative {
    my $genelist = shift;
    my $cp = 0.0;

    $_->[1] = $cp += $_->[1] foreach @$genelist;
}

sub selectRandom {
    my $genelist = shift;
    my $number = shift || 1;
    my @r = gen_random(1, $number);

    my $s;
    foreach my $r (@r) {
        foreach (@$genelist){
            if ($r < $_->[1]) { $s .= $_->[0]; last; }
        }
    }

    return $s;
}


sub makeRandomFasta {
    my ($id, $desc, $n, $genelist) = @_;

    print ">", $id, " ", $desc, "\n" if $PRINT;

    # print whole lines
    foreach (1 .. int($n / LINELENGTH) ){
            my $dummy = selectRandom($genelist, LINELENGTH)."\n";
            print $dummy if $PRINT;
    }
    # print remaining line (if required)
    if ($n % LINELENGTH){
            my $dummy = selectRandom($genelist, $n % LINELENGTH)."\n";
            print $dummy if $PRINT;
    }
}

sub makeRepeatFasta {
    my ($id, $desc, $s, $n) = @_;

    print ">", $id, " ", $desc, "\n" if $PRINT;

    my $r = length $s;
    my $ss = $s . $s . substr($s, 0, $n % $r);
    for my $j(0..int($n / LINELENGTH)-1) {
        my $i = $j*LINELENGTH % $r;
        my $dummy = substr($ss, $i, LINELENGTH)."\n";
        print $dummy if $PRINT;
    }
    if ($n % LINELENGTH) {
            my $dummy = substr($ss, -($n % LINELENGTH)). "\n";
            print $dummy if $PRINT;
    }
}


my $iub = [
    [ 'a', 0.27 ],
    [ 'c', 0.12 ],
    [ 'g', 0.12 ],
    [ 't', 0.27 ],
    [ 'B', 0.02 ],
    [ 'D', 0.02 ],
    [ 'H', 0.02 ],
    [ 'K', 0.02 ],
    [ 'M', 0.02 ],
    [ 'N', 0.02 ],
    [ 'R', 0.02 ],
    [ 'S', 0.02 ],
    [ 'V', 0.02 ],
    [ 'W', 0.02 ],
    [ 'Y', 0.02 ]
];

my $homosapiens = [
    [ 'a', 0.3029549426680 ],
    [ 'c', 0.1979883004921 ],
    [ 'g', 0.1975473066391 ],
    [ 't', 0.3015094502008 ]
];

my $alu =
    'GGCCGGGCGCGGTGGCTCACGCCTGTAATCCCAGCACTTTGG' .
    'GAGGCCGAGGCGGGCGGATCACCTGAGGTCAGGAGTTCGAGA' .
    'CCAGCCTGGCCAACATGGTGAAACCCCGTCTCTACTAAAAAT' .
    'ACAAAAATTAGCCGGGCGTGGTGGCGCGCGCCTGTAATCCCA' .
    'GCTACTCGGGAGGCTGAGGCAGGAGAATCGCTTGAACCCGGG' .
    'AGGCGGAGGTTGCAGTGAGCCGAGATCGCGCCACTGCACTCC' .
    'AGCCTGGGCGACAGAGCGAGACTCCGTCTCAAAAA';

######################################################################
#main

sub run
{
        my ($n) = @_;

        makeCumulative($iub);
        makeCumulative($homosapiens);

        makeRepeatFasta ('ONE', 'Homo sapiens alu', $alu, $n*2);
        makeRandomFasta ('TWO', 'IUB ambiguity codes', $n*3, $iub);
        makeRandomFasta ('THREE', 'Homo sapiens frequency', $n*5, $homosapiens);
}

sub main
{
        my ($options) = @_;

        $PRINT     = $options->{print};
        my $goal   = ($options->{fastmode} ? 200_000 : 1_000_000);
        my $count  = ($options->{fastmode} ? 1 : 5);

        my $result;
        my $t = timeit $count, sub { $result = run($goal) };
        return {
                Benchmark     => $t,
                goal          => $goal,
                count         => $count,
                result        => $result,
               };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Benchmark::Perl::Formance::Plugin::PerlStone2015::fasta - benchmark - Generate and write random DNA sequences

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
