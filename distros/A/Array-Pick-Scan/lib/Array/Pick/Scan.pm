package Array::Pick::Scan;

our $DATE = '2019-09-15'; # DATE
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(random_item);

sub random_item {
    my ($ary, $num_items) = @_;

    $num_items //= 1;

    my $ary_size = @$ary;

    my @items;
    if ($num_items == 1) {
        return $ary->[rand() * $ary_size];
    } else {
        for my $i (0..$ary_size-1) {
            if (@items < $num_items) {
                # we haven't reached $num_items, put item to result in a random
                # position
                splice @items, rand(@items+1), 0, $ary->[$i];
            } else {
                # we have reached $nnum_items, just replace an item randomly,
                # using algorithm from Learning Perl, slightly modified
                rand($i+1) < @items and
                    splice @items, rand(@items), 1, $ary->[$i];
            }
        }
        return @items;
    }
}

1;
# ABSTRACT: Pick random items from an array, without duplicates

__END__

=pod

=encoding UTF-8

=head1 NAME

Array::Pick::Scan - Pick random items from an array, without duplicates

=head1 VERSION

This document describes version 0.001 of Array::Pick::Scan (from Perl distribution Array-Pick-Scan), released on 2019-09-15.

=head1 SYNOPSIS

 use Array::Pick::Scan qw(random_item);
 my $item  = random_item(\@ary);
 my @items = random_line(\@ary, 3);

=head1 DESCRIPTION

This module can return random items from an array, without duplicates. It uses
the same algorithm as L<File::Random::Pick>, which in turn uses a slightly
modified version of algorithm described in L<perlfaq> (L<perldoc -q "random
line">)), but uses items from an array instead of lines from a file(handle).

This module is just a proof of concept and is NOT recommended for general use;
as its performance is inferior to L<List::Util>'s C<shuffle> or
L<List::MoreUtils>'s C<samples>.

=head1 FUNCTIONS

=head2 random_item

Usage:

 my @items = random_item(\@ary [ , $num_samples ]);

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

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
