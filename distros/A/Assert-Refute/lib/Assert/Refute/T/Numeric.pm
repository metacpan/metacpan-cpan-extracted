package Assert::Refute::T::Numeric;

use strict;
use warnings;
our $VERSION = '0.1201';

=head1 NAME

Assert::Refute::T::Numeric - Numeric tests for Assert::Refute suite.

=head1 SYNOPSIS

Somewhere in your unit-test:

    use Test::More;
    use Assert::Refute::T::Numeric; # must come *after* Test::More

    is_between 4 * atan2( 1, 1 ), 3.1415, 3.1416, "Pi number as expected";

    within_delta sqrt(sqrt(sqrt(10)))**8, 10, 1e-9, "floating point round-trip";

    within_relative 2**20, 1_000_000, 0.1, "10% precision for 1 mbyte";

    done_testing;

Same for production code:

    use Assert::Refute;
    use Assert::Refute::T::Numeric;

    my $rotate = My::Rotation::Matrix->new( ... );
    try_refute {
        within_delta $rotate->determinant, 1, 1e-6, "Rotation keeps distance";
    };

    my $total = calculate_price();
    try_refute {
        is_between $total, 1, 100, "Price within reasonable limits";
    };

=cut

use Carp;
use Scalar::Util qw(looks_like_number);
use parent qw(Exporter);

use Assert::Refute::Build;

=head2 is_between $x, $lower, $upper, [$message]

Note that $x comes first and I<not> between boundaries.

=cut

build_refute is_between => sub {
    my ($x, $min, $max) = @_;

    croak "Non-numeric boundaries: ".to_scalar($min, 0).",".to_scalar($max, 0)
        unless looks_like_number $min and looks_like_number $max;

    return "Not a number: ".to_scalar($x, 0)
        unless looks_like_number $x;

    return $min <= $x && $x <= $max ? '' : "$x is not in [$min, $max]";
}, args => 3, export => 1;

=head2 within_delta $x, $expected, $delta, [$message]

Test that $x differs from $expected value by no more than $delta.

=cut

build_refute within_delta => sub {
    my ($x, $exp, $delta) = @_;

    croak "Non-numeric boundaries: ".to_scalar($exp, 0)."+-".to_scalar($delta, 0)
        unless looks_like_number $exp and looks_like_number $delta;

    return "Not a number: ".to_scalar($x, 0)
        unless looks_like_number $x;

    return abs($x - $exp) <= $delta ? '' : "$x is not in [$exp +- $delta]";
}, args => 3, export => 1;

=head2 within_relative $x, $expected, $delta, [$message]

Test that $x differs from $expected value by no more than $expected * $delta.

=cut

build_refute within_relative => sub {
    my ($x, $exp, $delta) = @_;

    croak "Non-numeric boundaries: ".to_scalar($exp, 0)."+-".to_scalar($delta, 0)
        unless looks_like_number $exp and looks_like_number $delta;

    return "Not a number: ".to_scalar($x, 0)
        unless looks_like_number $x;

    return abs($x - $exp) <= abs($exp * $delta)
        ? ''
        : "$x differs from $exp by more than ".$exp*$delta;
}, args => 3, export => 1;

=head1 SEE ALSO

L<Test::Number::Delta>.

=head1 LICENSE AND COPYRIGHT

This module is part of L<Assert::Refute> suite.

Copyright 2017-2018 Konstantin S. Uvarin. C<< <khedin at cpan.org> >>

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1;
