package Benchmark::Perl::Formance::Plugin::PerlStone2015::revcomp;
our $AUTHORITY = 'cpan:SCHWIGON';
# ABSTRACT: benchmark - Read DNA sequences - write their reverse-complement
$Benchmark::Perl::Formance::Plugin::PerlStone2015::revcomp::VERSION = '0.002';
# COMMAND LINE:
# /usr/bin/perl revcomp.perl-4.perl 0 < revcomp-input25000000.txt

# The Computer Language Benchmarks Game
# http://shootout.alioth.debian.org/
#
# Contributed by Andrew Rodland
# Benchmark::Perl::Formance plugin by Steffen Schwigon

use strict;

#############################################################
#                                                           #
# Benchmark Code ahead - Don't touch without strong reason! #
#                                                           #
#############################################################

use File::ShareDir qw(dist_dir);
use Benchmark ':hireswallclock';
use Scalar::Util "reftype";


our $PRINT = 0;

sub print_reverse {
  no warnings 'uninitialized'; ## no critic
  while (my $chunk = substr $_[0], -60, 60, '') {
          my $dummy = scalar reverse($chunk);
          print $dummy, "\n" if $PRINT;
  }
}

sub run
{
        my ($infile) = @_;

        my $data;

        my $srcdir; eval { $srcdir = dist_dir('Benchmark-Perl-Formance-Cargo')."/Shootout" };
        return { failed => "no Benchmark-Perl-Formance-Cargo" } if $@;

        my $srcfile = "$srcdir/$infile";
        open my $INFILE, "<", $srcfile or return { failed => "Cannot read $srcfile" };

        while (<$INFILE>) {
                if (/^>/) {
                        print_reverse $data;
                        print if $PRINT;
                } else {
                        chomp;
                        tr{wsatugcyrkmbdhvnATUGCYRKMBDHVN}
                          {WSTAACGRYMKVHDBNTAACGRYMKVHDBN};
                        $data .= $_;
                }
        }
        close $INFILE;
        print_reverse $data;
}

sub main
{
        my ($options) = @_;

        $PRINT     = $options->{D}{Shootout_revcomp_print};
        my $goal   = $options->{fastmode} ? "fasta-1000000.txt" : "fasta-1000000.txt";
        my $count  = $options->{fastmode} ? 1 : 5;

        my $result;
        my $t = timeit $count, sub { $result = run($goal) };
        return $result if $result->{failed};

        return {
                Benchmark => $t,
                goal      => $goal,
                count     => $count,
                result    => $result,
               };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Benchmark::Perl::Formance::Plugin::PerlStone2015::revcomp - benchmark - Read DNA sequences - write their reverse-complement

=head1 CONFIGURATION

You can control whether to output the result in case you want to reuse
it:

   $ perl-formance --plugins=Shootout::revcomp \
                    -DShootout_revcomp_print=1

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
