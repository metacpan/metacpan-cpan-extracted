package Assert::Refute::T::Array;

use strict;
use warnings;
our $VERSION = '0.17';

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
use Scalar::Util qw( blessed reftype );
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

=cut

build_refute map_subtest => sub {
    my ($self, $code, $data, $message) = @_;

    $message ||= "map_subtest";

    $self->subcontract( $message => sub {
        return ok 0, "Not an array"
            unless reftype $data eq 'ARRAY';
        # Test::More doesn't regard empty tests as passing.
        ok 1, "empty array - automatic success"
            unless @$data;
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

=head1 AUTHOR

Konstantin S. Uvarin, C<< <khedin at gmail.com> >>

=head1 BUGS

Please report bugs via github or RT:

=over

=item * L<https://github.com/dallaylaen/assert-refute-t-extra/issues>

=item * C<bug-assert-refute-t-array at rt.cpan.org>

=item * L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Assert-Refute-T-Array>

=back

=head1 SUPPORT

You can find documentation for this module with the C<perldoc> command.

    perldoc Assert::Refute::T::Array

You can also look for information at:

=over 4

=item * github: L<https://github.com/dallaylaen/assert-refute-t-extra>

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Assert-Refute-T-Array>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Assert-Refute-T-Array>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Assert-Refute-T-Array>

=item * Search CPAN

L<http://search.cpan.org/dist/Assert-Refute-T-Array/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2018 Konstantin S. Uvarin.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;
