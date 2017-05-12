package Benchmark::Perl::Formance::Plugin::FibOOSig;
our $AUTHORITY = 'cpan:SCHWIGON';
# ABSTRACT: benchmark plugin - FibOOSig - Stress recursion and method calls (plain OO with function signatures)

# Fibonacci numbers, using methods with signatures (Perl 5.20+)

BEGIN {
        if ($] < 5.020) {
                die "Perl 5.020+ required for subs with signatures.\n";
        }
}

use strict;
use warnings;
use experimental 'signatures';
no warnings 'experimental::signatures';

our $VERSION = "0.002";

#############################################################
#                                                           #
# Benchmark Code ahead - Don't touch without strong reason! #
#                                                           #
#############################################################

our $goal;
our $count;

use Benchmark ':hireswallclock';

sub new {
        bless {}, shift;
}

sub fib ($self, $n)
{
        $n < 2
            ? 1
            : $self->fib($n-1) + $self->fib($n-2);
}

sub main
{
        my ($options) = @_;

        # ensure same values over all Fib* plugins!
        $goal  = $options->{fastmode} ? 20 : 35;
        $count = 5;

        my $result;
        my $fib = __PACKAGE__->new;
        my $t   = timeit $count, sub { $result = $fib->fib($goal) };
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

Benchmark::Perl::Formance::Plugin::FibOOSig - benchmark plugin - FibOOSig - Stress recursion and method calls (plain OO with function signatures)

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
