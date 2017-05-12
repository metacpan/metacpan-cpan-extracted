# $Id: Register.pm,v 1.6 2008/02/26 21:54:55 drhyde Exp $

package CPU::Emulator::Z80::Register;

use vars qw($VERSION);

$VERSION = '1.0';

use CPU::Emulator::Z80::ALU;

=head1 NAME

CPU::Emulator::Z80::Register - a register for a Z80

=head1 DESCRIPTION

This is a base class that defines some useful routines for
registers of any size.

=head1 METHODS

The following methods exist in the base class:

=head2 getsigned

Decodes the register 2s-complement-ly and return a signed value.

=cut

sub getsigned {
    my $self = shift;
    my $value = $self->get();
    return ALU_getsigned($value, $self->{bits});
}

=head2 cpu

Return a reference to the CPU this object lives in.

=cut

sub cpu { shift()->{cpu}; }

=head2 inc

Increment the register.  But note that if incrementing means you
need to do anything else, such as set flags, you will need to
override this.

=cut

sub inc {
    my $self = shift();
    $self->set($self->get() + 1);
}

=head2 dec

Decrement the register, again without bothering with flags and
stuff so override if necessary.

=cut

sub dec {
    my $self = shift;
    $self->set($self->get() - 1);
}

=pod

and the following methods need to be defined in all sub-classes:

=head2 get, set

Must be over-ridden in
sub-classes such
that setting stores a value, truncated to the right length, and
getting retrieves a value, truncated to the right length.

The set() method must accept -ve values and store them in
2s-complement.  Its behaviour is undefined if the user is foolish
enough to store too large a -ve value.

The get() method must return the value assuming it to be unsigned.

=head1 FIELDS

All subclasses must have the following fields:

=head2 bits

The number of bits in the register

=head2 cpu

A reference to the CPU this register resides in - this is so that
mathemagical operators can get at the flags register.

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
