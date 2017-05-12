# $Id: Register8.pm,v 1.6 2008/02/23 20:07:01 drhyde Exp $

package CPU::Emulator::Z80::Register8;

use strict;
use warnings;

use vars qw($VERSION);

use base qw(CPU::Emulator::Z80::Register);
use CPU::Emulator::Z80::ALU;

$VERSION = '1.0';

=head1 NAME

CPU::Emulator::Z80::Register8 - an 8 bit register for a Z80

=head1 DESCRIPTION

This class implements an 8-bit register for a Z80.

=head1 METHODS

=head2 new

Returns an object.  Takes two or three named parameters:

=over

=item cpu

mandatory, a reference to the CPU this register lives in, mostly so
that operations on the register can get at the flags register.

=back

and either of:

=over

=item value

The value to initialise the register to;

=back

or

=over

=item get, set

Subroutines to call when getting/setting the register instead of
the default get/set methods.  The 'get' subroutine will be passed
no parameters, the 'set' subroutine will be passed the new value.
Consequently, they are expected to be closures if they are to be
of any use.

=back

=cut

sub new {
    my $class = shift;
    my $self = {@_, bits => 8};
    bless $self, $class;
}

=head2 get

Get the register's current value.

=cut

sub get {
    my $self = shift;
    if(exists($self->{get})) {
        return $self->{get}->();
    } else { return $self->{value} & 0xFF }
}

=head2 set

Set the register's value to whatever is passed in as a parameter.

=cut

sub set {
    my $self = shift;
    if(exists($self->{set})) {
        return $self->{set}->(shift);
    } else { $self->{value} = shift() & 0xFF }
}

=head2 inc

Increment the register and set flags.

=cut

sub inc {
    my $self = shift;
    my $flags = $self->cpu()->register('F');
    $self->set(ALU_inc8($flags, $self->get()));
}

=head2 dec

Decrement the register and set flags.

=cut

sub dec {
    my $self = shift;
    my $flags = $self->cpu()->register('F');
    $self->set(ALU_dec8($flags, $self->get()));
}

=head2 add

Add the specified value to the register.

=cut

sub add {
    my($self, $op) = @_;
    $self->set(ALU_add8($self->cpu()->register('F'), $self->get(), $op));
}

=head2 sub

Subtract the specified value from the register.

=cut

sub sub {
    my($self, $op) = @_;
    $self->set(ALU_sub8($self->cpu()->register('F'), $self->get(), $op));
}

=head1 BUGS/WARNINGS/LIMITATIONS

None known.

=head1 AUTHOR, COPYRIGHT and LICENCE

Copyright 2008 David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

This software is free-as-in-speech software, and may be used,
distributed, and modified under the terms of either the GNU
General Public Licence version 2 or the Artistic Licence.  It's
up to you which one you use.  The full text of the licences can
be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=cut

1;
