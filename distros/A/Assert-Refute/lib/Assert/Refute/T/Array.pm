package Assert::Refute::T::Array;

use strict;
use warnings;
our $VERSION = '0.1301';

=head1 NAME

Assert::Refute::T::Array - Assertions about arrays for Assert::Refute suite

=head1 SYNOPSIS

Add C<array_of> and C<is_sorted> checks to both runtime checks
and unit test scripts.

    use Test::More;
    use Assert::Refute qw(:core);
    use Assert::Refute::T::Array;

Testing that array consists of given values:

    array_of [ "foo", "bar", "baz" ], qr/ba/, "This fails because of foo";

    array_of [
        { id => 42, name => "Answer to life" },
        { id => 137 },
    ], contract {
        package T;
        use Assert::Refute::T::Basic;
        like $_[0]->{name}, qr/^\w+$/;
        like $_[0]->{id}, qr/^\d+$/;
    }, "This also fails";

Testing that array is ordered:

    is_sorted { $a lt $b } [sort qw(foo bar bar baz)],
        "This fails because of repetition";
    is_sorted { $a le $b } [sort qw(foo bar bar baz)],
        "This passes though";

Not only sorting, but other types of partial order can be tested:

    is_sorted { $b->{start_date} eq $a->{end_date} }, \@reservations,
        "Next reservation aligned with the previous one";

=head1 EXPORTS

All of the below functions are exported by default:

=cut

use Carp;
use Scalar::Util qw(blessed);
use parent qw(Exporter);

our @EXPORT = qw(array_of);

use Assert::Refute::Build;
use Assert::Refute qw(:all); # TODO oo interface in internals, plz

=head2 array_of

    array_of \@list, $criteria, [ "message" ]

Check that I<every> item in the list matches criteria, which may be one of:

=over

=item * regex - just match against regular expression;

=item * a functions - execute that function inside a single subcontract;

=item * L<Assert::Refute::Contract> - pass each element as argument to
a I<separate> subcontract.

=back

=cut

build_refute array_of => sub {
    my ($self, $list, $match, $message) = @_;

    $message ||= "list of";
    $self->subcontract( $message => sub {
        my $report = shift;

        # TODO 0.30 mention list element number
        if (ref $match eq 'Regexp') {
            foreach (@$list) {
                $report->like( $_, $match );
            };
        } elsif (blessed $match && $match->isa("Assert::Refute::Contract")) {
            foreach (@$list) {
                $report->subcontract( "list item" => $match, $_ );
            };
        } elsif (UNIVERSAL::isa( $match, 'CODE' )) {
            foreach (@$list) {
                $match->($report, $_);
            };
        } else {
            croak "array_of: unknown criterion type: ".(ref $match || 'SCALAR');
        };
    } ); # end subcontract
}, export => 1, manual => 1, args => 2;

=head2 is_sorted

    is_sorted { $a ... $b } \@list, "message";

Check that condition about ($a, $b) holds
for every two subsequent items in array.

Consider using C<reduce_subtest{ $a ... $b }> instead if there's a complex
condition inside.

=cut

build_refute is_sorted => sub {
    my ($block, $list) = @_;

    return '' if @$list < 2;

    # Unfortunately, $a and $b are package variables
    # of the *calling* package...
    # So localize them through a hack.
    my ($refa, $refb) = do {
        my $caller = caller 1;
        no strict 'refs'; ## no critic - need to localize $a and $b
        \(*{$caller."::a"}, *{$caller."::b"});
    };
    local (*$refa, *$refb);

    my @bad;
    for( my $i = 0; $i < @$list - 1; $i++) {
        *$refa = \$list->[$i];
        *$refb = \$list->[$i+1];
        $block->() or push @bad, "($i, ".($i+1).")";
    };

    return !@bad ? '' : 'Not ordered pairs: '.join(', ', @bad);
}, block => 1, args => 1, export => 1;

=head2 map_subtest { ok $_ } \@list, "message";

Execute a subcontract that applies checks in { ... }
to every element of an array.

Return value of code block is B<ignored>.

Automatically succeeds if there are no elements.

B<[EXPERIMENTAL]> Name and meaning may change in the future.

=cut

build_refute map_subtest => sub {
    my ($self, $code, $data, $message) = @_;

    $message ||= "map_subtest";

    $self->subcontract( $message => sub {
        $code->($_[0]) for @$data;
    } );
}, block => 1, export => 1, manual => 1, args => 1;

=head2 reduce_subtest { $a ... $b } \@list, "message";

Applies checks in { ... } to every pair of subsequent elements in list.
The element with lower number is $a, and with higher number is $b.

    reduce_subtest { ... } [1,2,3,4];

would induce pairs:

    ($a = 1, $b = 2), ($a = 2, $b = 3), ($a = 3, $b = 4)

Return value of code block is B<ignored>.

Automatically succeeds if list has less than 2 elements.

B<[EXPERIMENTAL]> Name and meaning may change in the future.

=cut

build_refute reduce_subtest => sub {
    my ($self, $block, $list, $name) = @_;

    $name ||= "reduce_subtest";
    # empty list always ok
    return $self->refute( 0, $name ) if @$list < 2;

    # Unfortunately, $a and $b are package variables
    # of the *calling* package...
    # So localize them through a hack.
    my ($refa, $refb) = do {
        my $caller = caller 1;
        no strict 'refs'; ## no critic - need to localize $a and $b
        \(*{$caller."::a"}, *{$caller."::b"});
    };

    $self->subcontract( $name => sub {
        local (*$refa, *$refb);
        for( my $i = 0; $i < @$list - 1; $i++) {
            *$refa = \$list->[$i];
            *$refb = \$list->[$i+1];
            $block->($_[0]);
        };
    });
}, block => 1, export => 1, manual => 1, args => 1;

=head1 LICENSE AND COPYRIGHT

This module is part of L<Assert::Refute> suite.

Copyright 2017-2018 Konstantin S. Uvarin. C<< <khedin at cpan.org> >>

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1;
