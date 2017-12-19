package Assert::Refute::Contract;

use 5.006;
use strict;
use warnings;
our $VERSION = 0.0305;

=head1 NAME

Assert::Refute::Contract - Contract definition class for Assert::Refute suite

=head1 DESCRIPTION

This class represents a contract and is thus immutable.

See L<Assert::Refute::Exec> for its I<application> to a specific case.

=head1 SYNOPSIS

    use Assert::Refute::Contract;

    my $contract = Assert::Refute::Contract->new(
        code => sub {
            my ($c, $life) = @_;
            $c->is( $life, 42 );
        },
        need_object => 1,
    );

    # much later
    my $result = $contract->apply( 137 );
    $result->count;      # 1
    $result->is_passing; # 0
    $result->as_tap;     # Test::More-like summary

=head1 DESCRIPTION

This is a contract B<specification> class.
See L<Assert::Refute::Exec> for execution log.
See L<Assert::Refute/contract> for convenient interface.

=cut

use Carp;

use Assert::Refute::Exec;

our @CARP_NOT = qw(Assert::Refute Assert::Refute::Build);

=head1 OBJECT-ORIENTED INTERFACE

=head2 new

    Assert::Refute::Contract->new( %options );

%options may include:

=over

=item * C<code> (required) - contract to be executed

=item * C<need_object> - if given, a contract execution object
will be prepended to C<code>'s argument list,
as if it was a method.

This allows to run a contract without exporting anything to the calling
package.

The name is not final, better suggestions wanted.

=item * C<args> = n or C<args> = [min, max] - set limitation on
the number of accepted parameters.
Negative maximum value means unlimited.

=back

=cut

my @new_required  = qw( code );
my @new_essential = (@new_required, qw( need_object args ));
my @new_optional  = qw( backend );

my %new_arg;
$new_arg{$_}++ for @new_essential, @new_optional;

my $def_backend = "Assert::Refute::Exec";

sub new {
    my ($class, %opt) = @_;

    my @missing = grep { !$opt{$_} } @new_required;
    croak( "Missing required arguments: @missing" )
        if @missing;
    croak( "'code' argument must be a subroutine" )
        unless UNIVERSAL::isa($opt{code}, 'CODE');
    my @extra = grep { !$new_arg{$_} } keys %opt;
    croak( "Unknown options: @extra" )
        if @extra;

    $opt{need_object}   = $opt{need_object} ? 1 : 0;

    # argument count:
    # * n means exactly n
    # * (n, m) means from n to m
    # * (n, 0) means from n to inf
    my $args = delete $opt{args};
    $args = [0, -1] unless defined $args; # == 0 is ok
    $args = [ $args, $args ] unless ref $args eq 'ARRAY';
    $args->[1] = 9**9**9 if $args->[1] < 0;
    croak "Meaningless argument limits [$args->[0], $args->[1]]"
        unless $args->[0] <= $args->[1];
    $opt{minarg} = $args->[0];
    $opt{maxarg} = $args->[1];

    # TODO validate backend
    $opt{backend}    ||= $def_backend;

    bless \%opt, $class;
};

=head2 adjust( %overrides )

Return a copy of this object with some overridden fields.

The name is not perfect, better ideas wanted.

%overrides may include:

=over

=item * backend - the class to perform tests.

=back

=cut

sub adjust {
    my ($self, %opt) = @_;

    my @dont = grep { $opt{$_} } @new_essential;
    croak( "Attempt to override essential parameters @dont" )
        if @dont;

    return (ref $self)->new( %$self, %opt );
};

=head2 apply( @parameters )

Spawn a new execution log object and run contract against it.

Returns a locked L<Assert::Refute::Exec> instance.

=cut

sub apply {
    my ($self, @args) = @_;

    my $c = $self->{backend};
    $c = $c->new unless ref $c;
    # TODO plan tests, argument check etc

    croak "contract->apply: expected from $self->{minarg} to $self->{maxarg} parameters"
        unless $self->{minarg} <= @args and @args <= $self->{maxarg};

    unshift @args, $c if $self->{need_object};
    local $Assert::Refute::Build::BACKEND = $c;
    eval {
        $self->{code}->( @args );
        $c->done_testing
            unless $c->is_done;
        1;
    } || do {
        $c->done_testing($@ || "Unexpected end of tests");
    };

    # At this point, done_testing *has* been called unless of course
    #    it is broken and dies, in which case tests will fail.
    return $c;
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

1; # End of Assert::Refute
