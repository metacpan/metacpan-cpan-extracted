package Benchmark::Perl::Formance::Plugin::PerlStone2015::mandelbrot;
our $AUTHORITY = 'cpan:SCHWIGON';
# ABSTRACT: benchmark - Generate Mandelbrot set portable bitmap file
$Benchmark::Perl::Formance::Plugin::PerlStone2015::mandelbrot::VERSION = '0.002';
# COMMAND LINE:
# /usr/bin/perl mandelbrot.perl 16000

# The Computer Language Benchmarks Game
# http://shootout.alioth.debian.org/
# implemented by Greg Buchholz
# streamlined by Kalev Soikonen
# parallelised by Philip Boulain
# modified by Jerry D. Hedden
# Benchmark::Perl::Formance plugin by Steffen Schwigon
# - nr of threads now dynamically

use strict;
use warnings;
use threads;

#############################################################
#                                                           #
# Benchmark Code ahead - Don't touch without strong reason! #
#                                                           #
#############################################################

use Benchmark ':hireswallclock';

use constant ITER     => 50;
use constant LIMITSQR => 2.0 ** 2;
use constant MAXPIXEL => 524288; # Maximum pixel buffer per thread

my ($w, $h);
my $threads;

# Generate pixel data for a single dot
sub dot($$) { ## no critic
   my ($Zr, $Zi, $Tr, $Ti) = (0.0,0.0,0.0,0.0);
   my $i = ITER;
   my $Cr = 2 * $_[0] / $w - 1.5;
   my $Ci = 2 * $_[1] / $h - 1.0;
   (
      $Zi = 2.0 * $Zr * $Zi + $Ci,
      $Zr = $Tr - $Ti + $Cr,
      $Ti = $Zi * $Zi,
      $Tr = $Zr * $Zr
   ) until ($Tr + $Ti > LIMITSQR || !$i--);
   return ($i == -1);
}

# Generate pixel data for range of lines, inclusive
sub lines($$) { ## no critic
   map { my $y = $_;
      pack 'B*', pack 'C*', map dot($_, $y), 0..$w-1;
   } $_[0]..$_[1]
}

sub num_cpus {
  open my $fh, '<', '/proc/cpuinfo' or return;
  my $cpus;
  while (<$fh>) {
          $cpus ++ if /^processor[\s]+:/; # 0][]0]; # for emacs cperl-mode indent bug
  }
  return $cpus;
}

sub run
{
        $w = $h = shift;
        $threads = num_cpus() + 1; # Workers; ideally slightly overshoots number of processors

        # Decide upon roughly equal batching of workload, within buffer limits
        $threads = $h if $threads > $h;
        my $each = int($h / $threads);
        $each = int(MAXPIXEL / $w) if ($each * $w) > MAXPIXEL;
        $each = 1 if $each < 1;

        # Work as long as we have lines to spawn for or threads to collect from
        $| = 1;
        #print "P4\n$w $h\n";
        my $y = 0;
        my @workers;
        while (@workers or ($y < $h)) {
                # Create workers up to requirement
                while ((@workers < $threads) and ($y < $h)) {
                        my $y2 = $y + $each;
                        $y2 = $h if $y2 > $h;
                        push(@workers, threads->create('lines', $y, $y2 - 1));
                        $y = $y2;
                }
                # Block for result from the leading thread (to keep output in order)
                my $next = shift @workers;
                #print
                $next->join();
        }
}

sub main
{
        my ($options) = @_;

        my $goal   = $options->{fastmode} ? 400 : 2_000;
        my $count  = $options->{fastmode} ? 1   : 5;

        my $result;
        my $t = timeit $count, sub { $result = run($goal) };
        return {
                Benchmark => $t,
                goal      => $goal,
                count     => $count,
                # result    => $result, # useless here
                threads   => $threads,
                w         => $w,
                h         => $h,
               };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Benchmark::Perl::Formance::Plugin::PerlStone2015::mandelbrot - benchmark - Generate Mandelbrot set portable bitmap file

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
