package Array::Pick::Scan;

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-05-21'; # DATE
our $DIST = 'Array-Pick-Scan'; # DIST
our $VERSION = '0.005'; # VERSION

our @EXPORT_OK = qw(random_item pick);

sub random_item {
    my ($src, $num_items, $opts) = @_;
    my $ref = ref $src;

    $num_items //= 1;
    $opts //= {};

    if ($ref eq 'ARRAY') {
        my $ary = $src;
        my $ary_size = @$ary;

        if (!$ary_size) {
            return ();
        } elsif ($num_items == 1) {
            my $idx = int(rand() * $ary_size);
            return $opts->{pos} ? $idx : $ary->[$idx];
        } else {
            my @items;
            for my $i (0..$ary_size-1) {
                if (@items < $num_items) {
                    # we haven't reached $num_items, insert item to array in a
                    # random position
                    my $idx = int(rand(@items+1));
                    splice @items, $idx, 0, ($opts->{pos} ? $i : $ary->[$i]);
                } else {
                    # we have reached $num_items, just replace an item randomly,
                    # using algorithm from Learning Perl, slightly modified
                    if (rand($i+1) < @items) {
                        my $idx = int(rand(@items));
                        splice @items, $idx, 1, ($opts->{pos} ? $i : $ary->[$i]);
                    }
                }
            }
            return @items;
        }
    } elsif ($ref eq 'CODE') {
        my $iter = $src;
        my @items;
        my $i = -1;
        while (defined(my $item = $iter->())) {
            $i++;
            if (@items < $num_items) {
                # we haven't reached $num_items, insert item to array in a
                # random position
                    my $idx = int(rand(@items+1));
                splice @items, $idx, 0, ($opts->{pos} ? $i : $item);
            } else {
                # we have reached $num_items, just replace an item randomly,
                # using algorithm from Learning Perl, slightly modified
                if (rand($i+1) < @items) {
                    my $idx = int(rand(@items));
                    splice @items, $idx, 1, $opts->{pos} ? $i : $item;
                }
            }
        }
        return @items;
    } else {
        die "Please specify arrayref or coderef iterator as source of items";
    }
}

{
    no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict
    *pick = \&random_item;
}

1;
# ABSTRACT: Pick random items from an array (or iterator), without duplicates

__END__

=pod

=encoding UTF-8

=head1 NAME

Array::Pick::Scan - Pick random items from an array (or iterator), without duplicates

=head1 VERSION

This document describes version 0.005 of Array::Pick::Scan (from Perl distribution Array-Pick-Scan), released on 2022-05-21.

=head1 SYNOPSIS

 use Array::Pick::Scan qw(pick);

 my $item  = pick(\@ary);
 my @items = pick(\@ary, 3);

or:

 my $item  = pick(\&iterator);
 my @items = pick(\&iterator, 3);

To return array indexes instead of the items:

 my @item  = pick($source, $n, {pos=>1});

=head1 DESCRIPTION

This module can return random items from an array (or iterator), without
duplicate elements (i.e. random sampling without replacement). It uses the same
algorithm as L<File::Random::Pick>, which in turn uses a slightly modified
version of algorithm described in L<perlfaq> (L<perldoc -q "random line">)), but
uses items from an array/iterator instead of lines from a file(handle).

Performance-wise, this module is inferior to L<List::Util>'s C<shuffle> or
L<List::MoreUtils>'s C<samples>, but can be useful in cases where you have an
iterator and do not want to put all the iterator's items into memory first.

=head1 FUNCTIONS

=head2 pick

Usage:

 my @items = pick(\@ary      [ , $num_samples [ , \%opts ] ]);
 my @items = pick(\&iterator [ , $num_samples [ , \%opts ] ]);

Number of samples defaults to 1.

Options:

=over

=item * pos

Bool. If set to true, will return array indexes instead of the items.

=back

=head2 random_item

Older name for L</pick>, deprecated and will be removed in future releases.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Array-Pick-Scan>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Array-Pick-Scan>.

=head1 SEE ALSO

L<File::Random::Pick> uses a similar algorithm.

L<List::Util>'s C<shuffle>, L<List::MoreUtils>'s C<samples>, L<List::AllUtils>'s
C<sample>.

L<Array::Sample::SimpleRandom> provides random sampling without replacement
(same as picking in this module) as well as with replacement (creating possible
duplicate items).

L<Array::Sample::WeightedRandom> lets you add weighting to each item.

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

This software is copyright (c) 2022, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Array-Pick-Scan>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
