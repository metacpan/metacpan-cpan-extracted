# -*- mode: cperl -*-
use 5.008;
use strict;
use warnings;

package Benchmark::Perl::Formance::Plugin::PerlStone2015;
# git description: v0.001-3-g97bd876

our $AUTHORITY = 'cpan:SCHWIGON';
# ABSTRACT: Benchmark::Perl::Formance plugin covering a representative set of sub benchmarks
$Benchmark::Perl::Formance::Plugin::PerlStone2015::VERSION = '0.002';
use Data::DPath 'dpath', 'dpathi';
use Config;

our @default_subtests = qw( binarytrees
                            fasta
                            regex

                            regexdna
                            nbody
                            revcomp
                            spectralnorm
                            fib

                            01overview
                            02bits
                            03operator
                            04control
                            05regex
                            06subroutines
                            07lists
                            08capture
                            09data
                            10packages
                            11modules
                            12objects
                            13overloading
                            14tie
                            15unicode
                            16ioipc
                            17concurrency
                            18compiling
                            19commandline
                         );

# Benchmarks using 'threads' can have an impact to programs running
# after them, so push them to the end of the list to avoid confusion
# as long as possible.
if ($Config{usethreads}) {
        push @default_subtests, (qw(fannkuch
                                    mandelbrot
                                  ));
}

sub perlstone
{
        my ($options) = @_;

        no strict "refs"; ## no critic

        my %results  = ();
        my $verbose  = $options->{verbose};
        my $subtests = $options->{subtests};
        my @subtests = scalar(@{$subtests||[]}) ? @{$subtests||[]} : @default_subtests;

        for my $subtest (@subtests)
        {
                print STDERR "#  - $subtest...\n" if $options->{verbose} > 2;
                eval "use ".__PACKAGE__."::$subtest"; ## no critic
                if ($@) {
                        print STDERR "# Skip PerlStone plugin '$subtest'" if $verbose;
                        print STDERR ":$@"                                if $verbose >= 2;
                        print STDERR "\n"                                 if $verbose;
                }
                else {
                        eval {
                                my $main = __PACKAGE__."::$subtest"."::main";
                                $results{$subtest} = $main->($options);
                        };
                        if ($@) {
                                $results{$subtest} = { failed => $@ };
                        }
                }
        }
        return \%results;
}

sub _find_sub_results
{
        my ($RESULTS) = @_;

        my %sub_results = ();

        my $benchmarks = dpathi($RESULTS)->isearch("//Benchmark");
        while ($benchmarks->isnt_exhausted) {
                my @keys;
                my $benchmark = $benchmarks->value;
                my $ancestors = $benchmark->isearch ("/::ancestor");

                while ($ancestors->isnt_exhausted) {
                        my $key = $ancestors->value->first_point->{attrs}{key};
                        push @keys, $key if defined $key;
                }
                $sub_results{join(".", reverse @keys)} = ${$benchmark->first_point->{ref}}->{Benchmark}[0];
        }
        return \%sub_results;
}

sub _aggregations
{
        my ($results, $options) = @_;

        my $sub_results = _find_sub_results($results);
        use Data::Dumper;
        #print STDERR "sub_results = ".Dumper($sub_results);

        my $basemean = 1; # calculate this from normalized sub_results
        return {
                #basemean => { Benchmark => [ $basemean ] },
                subresults => $sub_results,
               };
}

sub main
{
        my ($options) = @_;

        my $results = perlstone($options);

        $results->{perlstone} = _aggregations($results, $options);
        return $results;
}

1; # End of Benchmark::Perl::Formance::Plugin::PerlStone2015

__END__

=pod

=encoding UTF-8

=head1 NAME

Benchmark::Perl::Formance::Plugin::PerlStone2015 - Benchmark::Perl::Formance plugin covering a representative set of sub benchmarks

=head1 SYNOPSIS

=head2 Run benchmarks via perlformance frontend

 $ benchmark-perlformance -vv --plugin PerlStone2015

=head2 Start raw without any tooling

 $ perl -MData::Dumper -MBenchmark::Perl::Formance::Plugin::PerlStone2015 -e 'print Dumper(Benchmark::Perl::Formance::Plugin::PerlStone2015::main())'
 $ perl -MData::Dumper -MBenchmark::Perl::Formance::Plugin::PerlStone2015 -e 'print Dumper(Benchmark::Perl::Formance::Plugin::PerlStone2015::main({verbose => 3, fastmode => 1})->{perlstone}{subresults})'
 $ perl -MData::Dumper -MBenchmark::Perl::Formance::Plugin::PerlStone2015 -e 'print Dumper(Benchmark::Perl::Formance::Plugin::PerlStone2015::main({subtests => [qw(01overview regex)]})->{perlstone})'

=head2 AVAILABLE SUB BENCHMARKS

 binarytrees
 fasta
 regex

 regexdna
 nbody
 revcomp
 spectralnorm
 fib

 fannkuch                   # needs threaded perl
 mandelbrot                 # needs threaded perl

 01overview
 02bits                     # not yet implemented
 03operator                 # not yet implemented
 04control
 05regex
 06subroutines              # not yet implemented
 07lists
 08capture                  # not yet implemented
 09data
 10packages                 # not yet implemented
 11modules                  # not yet implemented
 12objects                  # not yet implemented
 13overloading              # not yet implemented
 14tie                      # not yet implemented
 15unicode                  # not yet implemented
 16ioipc                    # not yet implemented
 17concurrency              # not yet implemented
 18compiling                # not yet implemented
 19commandline              # not yet implemented

=head1 METHODS

=head2 main

Main entry point to start the benchmarks.

=head2 perlstone

The primary benchmarking function which in turn starts the sub
benchmarks.

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
