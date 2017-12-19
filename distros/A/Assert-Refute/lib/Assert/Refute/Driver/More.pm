package Assert::Refute::Driver::More;

use 5.006;
use strict;
use warnings;
our $VERSION = 0.0305;

=head1 NAME

Assert::Refute::Driver::More - Test::More compatibility layer for Asser::Refute suite

=head1 SYNOPSIS

In your test script:

    use Test::More;
    use Assert::Refute; # in that order

    my $def = contract {
        # don't use is/ok/etc here
        my ($c, @args) = @_;
        $c->is (...);
        $c->like (...);
    };

    is foo(), $bar, "Normal test";
    subcontract "Repeated test block 1", $def, $value1;
    like $string, qr/.../, "Another normal test";
    subcontract "Repeated test block 2", $def, $value2;

    done_testing;

=head1 DESCRIPTION

This class is useless in and of itself.
It is auto-loaded as a bridge between L<Test::More> and L<Assert::Refute>,
B<if> Test::More has been loaded B<before> Assert::Refute.

=head1 METHODS

We override some methods of L<Assert::Refute::Exec> below so that
test results are fed to the more backend.

=cut

use Carp;

use parent qw(Assert::Refute::Exec);

=head2 new

Will automatically load L<Test::Builder> instance,
which is assumed to be a singleton as of this writing.

=cut

sub new {
    my ($class, %opt) = @_;

    confess "Test::Builder not initialised, refusing toi proceed"
        unless Test::Builder->can("new");

    my $self = $class->SUPER::new(%opt);
    $self->{builder} = Test::Builder->new; # singletone this far
    $self;
};

=head2 refute( $condition, $message )

The allmighty refute() boils down to

     ok !$condition, $message
        or diag $condition;

=cut

sub refute {
    my ($self, $reason, $mess) = @_;

    # TODO bug - if refute() is called by itself, will report wrong
    local $Test::Builder::Level = $Test::Builder::Level + 2;

    # Keep track internally
    $self->{builder}->ok(!$reason, $mess);
    $self->SUPER::refute($reason, $mess);
};

=head2 done_testing

This dies. Use C<done_testing> in L<Test::More> instead.

=cut

sub done_testing {
    # We never stop!
    croak "Use Test::More native done_testing";
};

=head2 log_message( $indent, $level, $message )

Just fall back to diag/note.
Indentation is ignored.

=cut

sub log_message {
    my ($self, $indent, $level, @mess) = @_;

    if ($level == 1) {
        $self->{builder}->diag($_) for @mess;
    } elsif ($level > 1) {
        $self->{builder}->note($_) for @mess;
    };

    $self->SUPER::log_message( $indent, $level, @mess );
};

=head1 LICENSE AND COPYRIGHT

This module is part of L<Assert::Refute> suite.

Copyright 2017 Konstantin S. Uvarin. C<< <khedin at gmail.com> >>

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
