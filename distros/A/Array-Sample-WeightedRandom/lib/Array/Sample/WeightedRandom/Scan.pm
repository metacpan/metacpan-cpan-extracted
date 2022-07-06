package Array::Sample::WeightedRandom::Scan;

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-05-21'; # DATE
our $DIST = 'Array-Sample-WeightedRandom'; # DIST
our $VERSION = '0.004'; # VERSION

our @EXPORT_OK = qw(sample_weighted_random_no_replacement);

# this sub requires two iterator, the first one is to calculate sum of inverse
# weight for all items. then the second to scan and
sub _sample_weighted_random_no_replacement {
    my ($iter1, $iter2, $num_items, $opts) = @_;

    $num_items //= 1;
    $opts //= {};

    my @res; # each elem: [item, weight, pos]

    # iterate the first time to calculate sum of inverse weights for all items
    my $sum_of_inv_weights_all = 0;
    my $sum_of_weights_all = 0;
    while (defined(my $item = $iter1->())) {
        next if $item->[1] <= 0;
        $sum_of_weights_all     += $item->[1];
        $sum_of_inv_weights_all += 1/$item->[1];
    }
    #say "D: sum_of_weights_all=<$sum_of_weights_all>";

    my $sum_of_weights_iterated = 0;
    my $sum_of_weights_res = 0;
    my $sum_of_inv_weights_iterated = 0;
    my $sum_of_inv_weights_res = 0;
    my $i = -1;
    while (defined(my $item = $iter2->())) {
        $i++;

        next if $item->[1] <= 0;

        #use DD; print "D:item: "; dd $item;
        if (@res < $num_items) {
            # we haven't collected $num_items in @res, insert item to array in a
            # random position (adjusted by weights, so higher-weighted item will
            # tend to be at the front)

            if (!@res) {
                #say "D:added";
                push @res, [$item->[0], $item->[1], $i];
            } else {
                #say "D:inserting in random location";

                # UNUSED: weighted variant. note that this variant still does
                # not produce weighted position but biased towards the earilest
                # elements. thus earliest elements will sstill my $x =
                # rand($sum_of_weights_res + $item->[1]); say "D:
                # x=rand($sum_of_weights_res + $item->[1])=$x";

                #my $y = 0;
                #my $added;
                #for my $j (0 .. $#res) {
                #    my $elem = $res[$j];
                #    my $y2 = $y + $elem->[1];
                #    #say "D:  j=$j, $x >= $y && $x < $y2 ?";
                #    if ($x >= $y && $x < $y2) {
                #        my $idx = $j;
                #        #say "D:  inserted at position ".($j+1);
                #        splice @res, $j+1, 0, [$item->[0], $item->[1], $i];
                #        $added++;
                #        last;
                #    }
                #    $y = $y2;
                #}
                #unless ($added) {
                #    #say "D:  inserted at the end";
                #    push @res, [$item->[0], $item->[1], $i];
                #}

                # USED: uniform random variant. this variant inserts randomly so
                # does not take weight into account. weight will be taken into
                # account during replacing
                my $idx = rand(@res+1);
                splice @res, $idx, 0, [$item->[0], $item->[1], $i];

            }
            $sum_of_weights_res     += $item->[1];
            $sum_of_inv_weights_res += 1/$item->[1];

        } else {
            #say "D:maybe replacing (probability: rand($sum_of_inv_weights_iterated + 1/$item->[1]) < $sum_of_inv_weights_res)";
            # we have reached $num_items in @res, probabilistically replace an
            # item randomly, using algorithm from Learning Perl, slightly
            # modified to account for weights.
            if (rand($sum_of_inv_weights_iterated + 1/$item->[1]) < $sum_of_inv_weights_res) {
                my $x = rand($sum_of_inv_weights_res);
                #say "D:  x=rand($sum_of_inv_weights_res)=$x";
                my $y = 0;
                my $replaced;
                for my $j (0 .. $#res) {
                    my $elem = $res[$j];
                    my $y2 = $y + 1/$elem->[1];
                    if ($x >= $y && $x < $y2) {
                        my $idx = $j;
                        #say "D:  replacing at position $j";
                        my ($removed_elem) = splice @res, $j, 1, [$item->[0], $item->[1], $i];
                        $sum_of_weights_res     += $item->[1]   - $removed_elem->[1];
                        $sum_of_inv_weights_res += 1/$item->[1] - $removed_elem->[1];
                        $replaced++;
                        last;
                    }
                    $y = $y2;
                }
            } else {
                #say "D:  not replacing";
            }
        }

        $sum_of_weights_iterated     += $item->[1];
        $sum_of_inv_weights_iterated += 1/$item->[1];

    } # while iter

    if ($opts->{shuffle}) {
        require List::Util;
        @res = List::Util::shuffle(@res);
    }

    if ($opts->{pos}) {
        return map {$_->[2]} @res;
    } else {
        return map {$_->[0]} @res;
    }
}

sub sample_weighted_random_no_replacement {
    require Array::Iter;

    my ($ary, $n, $opts) = @_;

    my $iter1 = Array::Iter::array_iter($ary);
    my $iter2 = Array::Iter::array_iter($ary);
    _sample_weighted_random_no_replacement($iter1, $iter2, $n, $opts);
}

1;
# ABSTRACT: (DO NOT USE) Sample elements randomly, with weights, without replacement (using scan algorithm)

__END__

=pod

=encoding UTF-8

=head1 NAME

Array::Sample::WeightedRandom::Scan - (DO NOT USE) Sample elements randomly, with weights, without replacement (using scan algorithm)

=head1 VERSION

This document describes version 0.004 of Array::Sample::WeightedRandom::Scan (from Perl distribution Array-Sample-WeightedRandom), released on 2022-05-21.

=head1 SYNOPSIS

 use Array::Sample::WeightedRandom::Scan qw(sample_weighted_random_no_replacement);

 # "b" will be picked more often because it has a greater weight. it's also more
 # likely to be at the front of the samples.
 sample_weighted_random_with_replacement([ ["a",1], ["b",2.5] ], 1); => ("b")
 sample_weighted_random_with_replacement([ ["a",1], ["b",2.5] ], 1); => ("a")
 sample_weighted_random_with_replacement([ ["a",1], ["b",2.5] ], 1); => ("b")
 sample_weighted_random_no_replacement([ ["a",1], ["b",2.5] ], 5); => ("b", "a")

=head1 DESCRIPTION

B<DO NOT USE>. This algorithm currently produces biased results. Use
L<Array::Sample::WeightedRandom> instead.

This module provides L</sample_weighted_random_no_replacement> which is the same
as the one provided by L<Array::Sample::WeightedRandom> but uses the scan
algorithm. It actually scans the array twice instead of once.

=head1 FUNCTIONS

=head2 sample_weighted_random_no_replacement

See documentation of L<Array::Sample::WeightedRandom>.

=head1 FAQ

=head2 Why no sample_weighted_random_with_replacement?

This kind of sampling does not require scanning algorithm.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Array-Sample-WeightedRandom>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Array-Sample-WeightedRandom>.

=head1 SEE ALSO

L<Array::Sample::WeightedRandom>

Other sampling methods: L<Array::Sample::Partition>, L<Array::Sample::SysRand>,
L<Array::Sample::SimpleRandom>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Array-Sample-WeightedRandom>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
