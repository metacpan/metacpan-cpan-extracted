# -*- mode: cperl -*-
use 5.008;
use strict;
use warnings;

package Benchmark::Perl::Formance::Plugin::Mandelbrot;
# git description: 9f757a9

our $AUTHORITY = 'cpan:SCHWIGON';
# ABSTRACT: Benchmark::Perl::Formance plugin - more modern mandelbrot
$Benchmark::Perl::Formance::Plugin::Mandelbrot::VERSION = '0.001';
our @default_subtests = qw( withmce withthreads );

sub run
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

sub main
{
        my ($options) = @_;

        my $results = run($options);

        return $results;
}

1; # End of Benchmark::Perl::Formance::Plugin::PerlStone2015

__END__

=pod

=encoding UTF-8

=head1 NAME

Benchmark::Perl::Formance::Plugin::Mandelbrot - Benchmark::Perl::Formance plugin - more modern mandelbrot

=head1 SYNOPSIS

=head2 Run benchmarks via perlformance frontend

 $ benchmark-perlformance -vv --plugin PerlStone2015

=head2 Start raw without any tooling

 $ perl -MData::Dumper -MBenchmark::Perl::Formance::Plugin::PerlStone2015 -e 'print Dumper(Benchmark::Perl::Formance::Plugin::PerlStone2015::main())'
 $ perl -MData::Dumper -MBenchmark::Perl::Formance::Plugin::PerlStone2015 -e 'print Dumper(Benchmark::Perl::Formance::Plugin::PerlStone2015::main({verbose => 3, fastmode => 1})->{perlstone}{subresults})'
 $ perl -MData::Dumper -MBenchmark::Perl::Formance::Plugin::PerlStone2015 -e 'print Dumper(Benchmark::Perl::Formance::Plugin::PerlStone2015::main({subtests => [qw(01overview regex)]})->{perlstone})'

=head2 AVAILABLE SUB BENCHMARKS

 mandelbrot

=head1 METHODS

=head2 main

Main entry point to start the benchmarks.

=head2 run

Iterates over the available mandelbrot sub implementations and
collects the results.

=head2 AUTHOR

Mario Roy did the actual MCE-based Mandelbrot implementation.

Steffen Schwigon wrapped it into a
L<Benchmark::Perl::Formance|Benchmark::Perl::Formance> plugin.

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
