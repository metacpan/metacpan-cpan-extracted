package Assert::Refute::Driver::More;

use 5.006;
use strict;
use warnings;
our $VERSION = '0.1301';

=head1 NAME

Assert::Refute::Driver::More - Test::More compatibility layer for Asser::Refute suite

=head1 SYNOPSIS

In your test script:

    use Test::More;
    use Assert::Refute qw(:all); # in that order

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

We override some methods of L<Assert::Refute::Report> below so that
test results are fed to the more backend.

=cut

use Carp;

use parent qw(Assert::Refute::Report);
use Assert::Refute::Build qw(to_scalar);

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

    # TODO bug - if refute() is called directly as $contract->refute,
    # it will report the wrong file & line
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    $self->{count} = $self->{builder}->current_test;
    $self->{builder}->ok(!$reason, $mess);

    # see Assert::Refute::Report->get_result_detail
    if (ref $reason eq 'ARRAY') {
        $self->{builder}->diag(to_scalar($_)) for @$reason;
    } elsif ($reason and $reason ne 1) {
        $self->{builder}->diag(to_scalar($reason));
    };

    # Do we even need to track it here?
    $self->SUPER::refute($reason, $mess);
};

=head2 subcontract

Proxy to L<Test::More>'s subtest.

=cut

sub subcontract {
    my ($self, $mess, $todo, @args) = @_;

    $self->{builder}->subtest( $mess => sub {
        my $rep = (ref $self)->new( builder => $self->{builder} )->do_run(
            $todo, @args
        );
        # TODO also save $rep result in $self
    } );
};

=head2 done_testing

Proxy for C<done_testing> in L<Test::More>.

=cut

sub done_testing {
    my $self = shift;

    $self->{builder}->done_testing;
    $self->SUPER::done_testing;
};

=head2 do_log( $indent, $level, $message )

Just fall back to diag/note.
Indentation is ignored.

=cut

sub do_log {
    my ($self, $indent, $level, @mess) = @_;

    if ($level == -1) {
        $self->{builder}->diag($_) for @mess;
    } elsif ($level > 0) {
        $self->{builder}->note($_) for @mess;
    };

    $self->SUPER::do_log( $indent, $level, @mess );
};

=head2 get_count

Current test number.

=cut

sub get_count {
    my $self = shift;
    return $self->{builder}->current_test;
};

=head2 is_passing

Tell if the whole set is passing.

=cut

sub is_passing {
    my $self = shift;
    return $self->{builder}->is_passing;
};

=head2 get_result

Fetch result of n-th test.

0 is for passing tests, a true value is for failing ones.

=cut

sub get_result {
    my ($self, $n) = @_;

    return $self->{fail}{$n} || 0
        if exists $self->{fail}{$n};

    my @t = $self->{builder}->summary;
    $self->_croak( "Test $n has never been performed" )
        unless $n =~ /^[1-9]\d*$/ and $n <= @t;

    # Alas, no reason here
    return !$t[$n];
};

=head1 LICENSE AND COPYRIGHT

This module is part of L<Assert::Refute> suite.

Copyright 2017-2018 Konstantin S. Uvarin. C<< <khedin at cpan.org> >>

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1;
