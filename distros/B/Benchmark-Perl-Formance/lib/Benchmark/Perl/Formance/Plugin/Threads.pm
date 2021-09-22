package Benchmark::Perl::Formance::Plugin::Threads;
our $AUTHORITY = 'cpan:SCHWIGON';
# ABSTRACT: benchmark plugin - Threads - Stress threading

# Create threads to evaluate Fibonacci numbers

use 5.008;
use strict;
use warnings;

our $VERSION = "0.001";

#############################################################
#                                                           #
# Benchmark Code ahead - Don't touch without strong reason! #
#                                                           #
#############################################################

our $goal;
our $count;
our $threadcount;
our $val;
our $expect2;

use threads;

my $result;

use Benchmark ':hireswallclock';
use Data::Dumper;

sub run_thread_storm_noshared
{
        my ($options) = @_;

        my @t;
        foreach (1..$threadcount) {
                push @t, async {
                        # print STDERR ".";
                        1; # no-op
                }
        }
        foreach (@t) {
                $_->join;
        }

        return scalar @t;
}

sub threadstorm
{
        my ($options) = @_;

        $goal        = $options->{fastmode} ? 3 : 25;
        $threadcount = $options->{fastmode} ? 5 : ($options->{D}{Threads_threadcount} || 100);
        $val         = 25;
        $expect2     = $threadcount;

        my $ret2;
        my $t2 = timeit($goal, sub { $ret2 = run_thread_storm_noshared($options) });

        return {
                Benchmark   => $t2,
                threadcount => $threadcount,
                result      => $ret2,
                expect      => $expect2,
                useforks    => ($options->{useforks} || 0),
               };
}

sub main
{
        my ($options) = @_;

        return {
                threadstorm => threadstorm($options),
               };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Benchmark::Perl::Formance::Plugin::Threads - benchmark plugin - Threads - Stress threading

=head1 SYNOPSIS

Run it as any other plugin. You can define how many threads should
maximally be started. Default is 100.

  $ benchmark-perlformance --plugins=Threads -DThreads_threadcount=64

=head1 BUGS

Too naive. Really.

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
