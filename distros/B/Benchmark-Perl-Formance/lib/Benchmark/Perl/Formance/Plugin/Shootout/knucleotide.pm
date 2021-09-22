package Benchmark::Perl::Formance::Plugin::Shootout::knucleotide;
our $AUTHORITY = 'cpan:SCHWIGON';
# ABSTRACT: benchmark - Hashtable update and k-nucleotide strings

# COMMAND LINE:
# /usr/bin/perl knucleotide.perl 0 < knucleotide-input25000000.txt

#  The Computer Language Benchmarks Game
#  http://shootout.alioth.debian.org/

#  contributed by Karl FORNER
# (borrowed fasta loading routine from Kjetil Skotheim, 2005-11-29)
# Corrected again by Jesse Millikan
# revised by Kuang-che Wu
# Multi-threaded by Andrew Rodland
# Benchmark::Perl::Formance plugin by Steffen Schwigon

use strict;
use warnings;
use threads;

our $VERSION = "0.001";

#############################################################
#                                                           #
# Benchmark Code ahead - Don't touch without strong reason! #
#                                                           #
#############################################################

use File::ShareDir qw(dist_dir);
use Benchmark ':hireswallclock';
use Scalar::Util "reftype";

our $PRINT = 0;

my $threads;
my ($l,%h,$sum);
my ($sequence, $begin, $end);
my $output;

sub run
{
        my ($infile) = @_;

        $output = '';
        $threads = 2*num_cpus() || 1;

        my $srcdir; eval { $srcdir = dist_dir('Benchmark-Perl-Formance-Cargo')."/Shootout" };
        return { failed => "no Benchmark-Perl-Formance-Cargo" } if $@;

        my $srcfile = "$srcdir/$infile";
        open my $INFILE, "<", $srcfile or die "Cannot read $srcfile";

        $/ = ">";
        /^THREE/ and $sequence = uc(join "", grep !/^THREE/, split /\n+/) while <$INFILE>;

        close $INFILE;

        ($l,%h,$sum) = (length $sequence);

        foreach my $frame (1,2) {
                %h = ();
                update_hash_for_frame($frame);
                $sum = $l - $frame + 1;
                $output .= sprintf "$_ %.3f\n", $h{$_}*100/$sum for sort { $h{$b} <=> $h{$a} || $a cmp $b } keys %h;
                $output .= "\n";
        }

        foreach my $s (qw(GGT GGTA GGTATT GGTATTTTAATT GGTATTTTAATTTATAGT)) {
                update_hash_for_frame(length($s));
                $output .= sprintf "%d\t$s\n", $h{$s};
        }

        print $output if $PRINT;
}

sub update_hash_for_frame {
  my $frame = $_[0];
  my @threads;
  for my $i (0 .. $threads - 1) {
    use integer;
    my $begin = $l * $i / $threads;
    my $end = $l * ($i + 1) / $threads - 1;
    no integer;
    if ($end > $l - $frame) {
      $end = $l - $frame;
    }
    push @threads, threads->create(\&update_hash_slice, $frame, $begin, $end);
  }
  for my $thread (@threads) {
    my $count = $thread->join;
    $h{$_} += $count->{$_} for keys %$count;
  }
}

sub update_hash_slice {
  my ($frame, $begin, $end) = @_;
  my %local;
  $local{substr($sequence,$_,$frame)}++ for $begin .. $end;
  return \%local;
}

sub num_cpus {
  open my $fh, '<', '/proc/cpuinfo' or return;
  my $cpus;
  while (<$fh>) {
          $cpus ++ if /^processor[\s]+:/; # 0][]0]; # for emacs cperl-mode indent bug
  }
  return $cpus;
}

sub main
{
        my ($options) = @_;

        $PRINT     = $options->{D}{Shootout_knucleotide_print};
        my $goal   = $options->{fastmode} ? "fasta-25000.txt" : "fasta-1000000.txt";
        my $count  = $options->{fastmode} ? 1 : 5;

        my $result;
        my $t = timeit $count, sub { $result = run($goal) };
        return $result if reftype($result) eq "HASH" and $result->{failed};

        return {
                Benchmark => $t,
                goal      => $goal,
                count     => $count,
                result    => $result,
                threads   => $threads,
                l         => $l,
                sum       => $sum,
               };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Benchmark::Perl::Formance::Plugin::Shootout::knucleotide - benchmark - Hashtable update and k-nucleotide strings

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
