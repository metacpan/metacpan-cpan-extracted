package Benchmark::Perl::Formance::Plugin::PerlStone2015::mem;
our $AUTHORITY = 'cpan:SCHWIGON';
# ABSTRACT: benchmark - mem - memory operations
$Benchmark::Perl::Formance::Plugin::PerlStone2015::mem::VERSION = '0.002';
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

my @stuff;

sub allocate
{
        my ($options, $goal, $count) = @_;

        my $mygoal = ($options->{fastmode} ? 10 : 1) * $goal;
        my $t = timeit $count, sub {
                my @stuff1;
                $#stuff1 = $mygoal;
        };
        return {
                Benchmark  => $t,
                goal       => $mygoal,
                count      => $count,
               };
}

sub copy
{
        my ($options, $goal, $count) = @_;

        my $t = timeit $count, sub {
                my @copy = @stuff;
        };
        return {
                Benchmark  => $t,
                goal       => $goal,
                count      => $count,
               };
}

sub main
{
        my ($options) = @_;

        $goal  = $options->{fastmode} ? 2_000_000 : 15_000_000;
        $count = $options->{fastmode} ? 5 : 20;

        $#stuff = $goal;
        my $size;
        eval qq{use Devel::Size 'total_size'};
        if ($@) {
                $size = "error-no-Devel-Size-available";
        } else {
                $size = total_size(\@stuff);
        }

        return {
                total_size_bytes        => $size,
                copy                    => copy     ($options, $goal, $count),
                allocate                => allocate ($options, $goal, $count),
               };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Benchmark::Perl::Formance::Plugin::PerlStone2015::mem - benchmark - mem - memory operations

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
