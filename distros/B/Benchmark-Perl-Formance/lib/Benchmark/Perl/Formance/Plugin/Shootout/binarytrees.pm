package Benchmark::Perl::Formance::Plugin::Shootout::binarytrees;
our $AUTHORITY = 'cpan:SCHWIGON';
# ABSTRACT: benchmark - Allocate and deallocate many many binary trees

# COMMAND LINE:
# /usr/bin/perl binarytrees.perl-2.perl 20

# The Computer Language Benchmarks Game
# http://shootout.alioth.debian.org/
#
# Contributed by Doug King
# Corrected by Heiner Marxen
# Tree-building made non-recursive by Steffen Mueller
# Benchmark::Perl::Formance plugin by Steffen Schwigon

use strict;
use warnings;
use integer;
use Benchmark ':hireswallclock';

our $VERSION = "0.002";

#############################################################
#                                                           #
# Benchmark Code ahead - Don't touch without strong reason! #
#                                                           #
#############################################################

sub item_check {
    my ($tree) = @_;

    return $tree->[2] unless (defined $tree->[0]);
    return $tree->[2] + item_check($tree->[0]) - item_check($tree->[1]);
}


sub bottom_up_tree {
    my($depth) = @_;

    my @pool;
    push @pool, [undef, undef, -$_] foreach 0..2**$depth-1;

    foreach my $exponent (reverse(0..($depth-1))) {
        push @pool, [reverse(splice(@pool, 0, 2)), $_]
                       foreach reverse(-(2**$exponent-1) .. 0);
    }
    return $pool[0];
}

sub run {
        my ($n) = @_;

        my $min_depth = 4;
        my $max_depth;

        if ( ($min_depth + 2) > $n) {
                $max_depth = $min_depth + 2;
        } else {
                $max_depth = $n;
        }

        {
                my $stretch_depth = $max_depth + 1;
                my $stretch_tree = bottom_up_tree($stretch_depth);
                # print "stretch tree of depth $stretch_depth\t check: ",
                #     item_check($stretch_tree), "\n";
        }

        my $long_lived_tree = bottom_up_tree($max_depth);

        my $depth = $min_depth;
        while ( $depth <= $max_depth ) {
                my $iterations = 2 ** ($max_depth - $depth + $min_depth);
                my $check = 0;

                foreach my $i (1..$iterations) {
                        my $temp_tree = bottom_up_tree($depth);
                        $check += item_check($temp_tree);

                        $temp_tree = bottom_up_tree($depth);
                        $check += item_check($temp_tree);
                }

                #print $iterations * 2, "\t trees of depth $depth\t check: ", $check, "\n";
                $depth += 2;
        }

        # print "long lived tree of depth $max_depth\t check: ",
        #     item_check($long_lived_tree), "\n";
}

sub main
{
        my ($options) = @_;

        my $goal   = $options->{fastmode} ? 10 : 15;
        my $count  = $options->{fastmode} ?  1 :  5;

        my $result;
        my $t = timeit $count, sub { $result = run($goal) };
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

Benchmark::Perl::Formance::Plugin::Shootout::binarytrees - benchmark - Allocate and deallocate many many binary trees

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
