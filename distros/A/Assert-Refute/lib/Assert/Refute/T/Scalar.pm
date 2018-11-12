package Assert::Refute::T::Scalar;

use strict;
use warnings;
our $VERSION = '0.1501';

=head1 NAME

Assert::Refute::T::Scalar - Assertions about scalars for Assert::Refute suite.

=head1 SYNOPSIS

Currently only one check exists in this package, C<maybe_is>.

    use Test::More;
    use Assert::Refute::T::Scalar;

    maybe_is $foo, undef,          'Only passes if $foo is undefined';
    maybe_is $bar, 42,             'Only if undef or exact match';
    maybe_is $baz, qr/.../,        'Only if undef or matches regex';
    maybe_is $quux, sub { ok $_ }, 'Only if all refutations hold for $_';

    done_testing;

=head1 EXPORTS

All of the below functions are exported by default:

=cut

use Carp;
use parent qw(Exporter);

use Assert::Refute::Build;

=head2 maybe_is $value, $condition, "message"

Pass if value is C<undef>, apply condition otherwise.

Condition can be:

=over

=item * C<undef> - only undefined value fits;

=item * a plain scalar - an exact match expected (think C<is>);

=item * a regular expression - match it (think C<like>);

=item * anything else - assume it's subcontract.
The value in question will be passed as I<both> an argument and C<$_>.

=back

B<[EXPERIMENTAL]> This function may be removed for good
if it turns out too complex (I<see smartmatch debacle in Perl 5.27.7>).

=cut

build_refute maybe_is => sub {
    my ($self, $var, $cond, $message) = @_;

    return $self->refute(0, $message) unless defined $var;
    return $self->is( $var, $cond ) unless ref $cond;
    return $self->like( $var, $cond ) if ref $cond eq 'Regexp';

    $message ||= "maybe_is";
    local $_ = $var;
    return $self->subcontract( $message => $cond, $_ );
}, manual => 1, args => 2, export => 1;

=head1 LICENSE AND COPYRIGHT

This module is part of L<Assert::Refute> suite.

Copyright 2017-2018 Konstantin S. Uvarin. C<< <khedin at cpan.org> >>

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1;
