package Array::Pick::Scan;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-05-18'; # DATE
our $DIST = 'Array-Pick-Scan'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(random_item);

sub random_item {
    my ($src, $num_items) = @_;
    my $ref = ref $src;

    $num_items //= 1;

    if ($ref eq 'ARRAY') {
        my $ary = $src;
        my $ary_size = @$ary;

        if ($num_items == 1) {
            return $ary->[rand() * $ary_size];
        } else {
            my @items;
            for my $i (0..$ary_size-1) {
                if (@items < $num_items) {
                    # we haven't reached $num_items, insert item to array in a
                    # random position
                    splice @items, rand(@items+1), 0, $ary->[$i];
                } else {
                    # we have reached $num_items, just replace an item randomly,
                    # using algorithm from Learning Perl, slightly modified
                    rand($i+1) < @items and
                        splice @items, rand(@items), 1, $ary->[$i];
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
                splice @items, rand(@items+1), 0, $item;
            } else {
                # we have reached $num_items, just replace an item randomly,
                # using algorithm from Learning Perl, slightly modified
                rand($i+1) < @items and splice @items, rand(@items), 1, $item;
            }
        }
        return @items;
    } else {
        die "Please specify arrayref or coderef iterator as source of items";
    }
}

1;
# ABSTRACT: Pick random items from an array (or iterator), without duplicates

__END__

=pod

=encoding UTF-8

=head1 NAME

Array::Pick::Scan - Pick random items from an array (or iterator), without duplicates

=head1 VERSION

This document describes version 0.002 of Array::Pick::Scan (from Perl distribution Array-Pick-Scan), released on 2020-05-18.

=head1 SYNOPSIS

 use Array::Pick::Scan qw(random_item);

 my $item  = random_item(\@ary);
 my @items = random_line(\@ary, 3);

or:

 my $item  = random_item(\&iterator);
 my @items = random_line(\&iterator, 3);

=head1 DESCRIPTION

This module can return random items from an array (or iterator), without
duplicates. It uses the same algorithm as L<File::Random::Pick>, which in turn
uses a slightly modified version of algorithm described in L<perlfaq> (L<perldoc
-q "random line">)), but uses items from an array/iterator instead of lines from
a file(handle).

Performance-wise, this module is inferior to L<List::Util>'s C<shuffle> or
L<List::MoreUtils>'s C<samples>, but can be useful in cases where you have an
iterator and do not want to put all the iterator's items into memory first.

=head1 FUNCTIONS

=head2 random_item

Usage:

 my @items = random_item(\@ary      [ , $num_samples ]);
 my @items = random_item(\&iterator [ , $num_samples ]);

Number of samples defaults to 1.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Array-Pick-Scan>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Array-Pick-Scan>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Array-Pick-Scan>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<File::Random::Pick>

L<List::Util>'s C<shuffle>

L<List::MoreUtils>'s C<samples>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
