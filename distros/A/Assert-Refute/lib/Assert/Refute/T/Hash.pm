package Assert::Refute::T::Hash;

use strict;
use warnings;
our $VERSION = '0.1501';

=head1 NAME

Assert::Refute::T::Hash - Assertions about hashes for Assert::Refute suite

=head1 SYNOPSIS

    use Test::More;
    use Assert::Refute::T::Hash;

    keys_are { foo => 42, bar => 137 }, ["foo"], ["bar"], "Hash keys as expected";

=head1 EXPORTS

All of the below functions are exported by default:

=cut

use Carp;
use Scalar::Util qw(blessed);
use parent qw(Exporter);
our @EXPORT = qw(values_are);

use Assert::Refute::Build;
use Assert::Refute qw(:all); # TODO Assert::Refute::Contract please

=head2 keys_are \%hash, \@required, \@allowed, "Message"

Check that keys in hash are exactly as expected:

=over

=item * if \@required is present, make sure that all keys listed there exist;

=item * if \@allowed is present, make sure no keys are present
except those listed in either required or allowed.

=back

=cut

build_refute keys_are => sub {
    my ($hash, $required, $allowed) = @_;

    $required ||= [];

    my @missing = grep { !exists $hash->{$_} } @$required;
    my @extra;
    if ($allowed) {
        my %seen;
        $seen{$_}++ for @$required, @$allowed;
        @extra = grep { !exists $seen{$_} } keys %$hash;
    };

    my @msg;
    push @msg, "Required keys missing (@missing)" if @missing;
    push @msg, "Unexpected keys present (@extra)" if @extra;
    return join "; ", @msg;
}, args => 3, export => 1;

=head2 values_are \%hash, \%spec

For each key in %spec, check corresponding value in %hash:

=over

=item * if spec is C<undef>, only accept undefined or missing value;

=item * if spec is a string or number, check exact match (C<is>);

=item * if spec is a regular expression, apply it (C<like>);

=item * if spec is a contract or sub, apply it to the value (C<subcontract>);

=back

B<[NOTE]> This test should die if any other value appears in the spec.
However, it does not yet, instead producing a warning and
an unconditionally failed test.

=cut

build_refute values_are => sub {
    my ($self, $hash, $spec, $message) = @_;

    $message ||= "hash values as expected";
    $self->subcontract( $message => sub {
        foreach ( keys %$spec ) {
            my $cond = $spec->{$_};
            if (!ref $cond) {
                is $hash->{$_}, $cond, "$_ exact value";
            } elsif (ref $cond eq 'Regexp') {
                like $hash->{$_}, $cond, "$_ regex";
            } elsif (blessed $cond or UNIVERSAL::isa($cond, 'CODE')) {
                subcontract "$_ contract" => $cond, $hash->{$_};
            } else {
                # TODO bail_out when we can
                carp  "FIX TEST! Unexpected value in spec: '$_'=". ref $cond;
                croak "FIX TEST! Unexpected value in spec: '$_'=". ref $cond;
            };
        };
    });
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
