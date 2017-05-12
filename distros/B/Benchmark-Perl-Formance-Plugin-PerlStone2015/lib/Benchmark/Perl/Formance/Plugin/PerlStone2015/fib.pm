package Benchmark::Perl::Formance::Plugin::PerlStone2015::fib;
our $AUTHORITY = 'cpan:SCHWIGON';
# ABSTRACT: benchmark - Fibonacci - Stress recursion and function calls
$Benchmark::Perl::Formance::Plugin::PerlStone2015::fib::VERSION = '0.002';
use strict;
use warnings;

#############################################################
#                                                           #
# Benchmark Code ahead - Don't touch without strong reason! #
#                                                           #
#############################################################

our $goal;
our $count;

use Benchmark ':hireswallclock';

sub fib
{
        my $n = shift;

        $n < 2
            ? 1
            : fib($n-1) + fib($n-2);
}

sub main
{
        my ($options) = @_;

        # ensure same values over all fib* plugins!
        $goal  = $options->{fastmode} ? 28 : 35;
        $count = 5;

        my $result;
        my $t = timeit $count, sub { $result = fib $goal };
        return {
                Benchmark => $t,
                result    => $result,
                goal      => $goal,
               };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Benchmark::Perl::Formance::Plugin::PerlStone2015::fib - benchmark - Fibonacci - Stress recursion and function calls

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
