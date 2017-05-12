# $Id: Register8F.pm,v 1.6 2008/02/26 21:54:55 drhyde Exp $

package CPU::Emulator::Z80::Register8F;

use strict;
use warnings;

use vars qw($VERSION $AUTOLOAD);

use base qw(CPU::Emulator::Z80::Register8);

$VERSION = '1.0';

=head1 NAME

CPU::Emulator::Z80::Register8F - the flags register for a Z80

=head1 DESCRIPTION

This class is a ...::Register8 with additional methods for
getting at the individual flag bits

=head1 METHODS

It has the same methods as its parent, with the following additions:

=head2 getX/setX/resetX

where X can be any of S Z H P N C 5 or 3, where 5 and 3 are the
un-named bits 5 and 3 of the register (0 being the least-significant
bit).

getX takes no parameters and returns 1 or 0 depending
on the flag's status.

setX if called with no parameters sets the flag true.  If called with
a parameter it sets the flag true or false depending on the param's
value.

resetX takes no parameters and sets the flag false.

=cut

my %masks = (
    S => 0b10000000, # sign (copy of MSB)
    Z => 0b01000000, # zero
    5 => 0b00100000,
    H => 0b00010000, # half-carry (from bit 3 to 4)
    3 => 0b00001000,
    P => 0b00000100, # parity (set if even number of bits set)
                     # overflow (2-comp result doesn't fit in reg)
    N => 0b00000010, # subtract (was the last op a subtraction?)
    C => 0b00000001  # carry (result doesn't fit in register)
);

sub _get {
    my($self, $flag) = @_;
    return !!($self->get() & $flag)
}
sub _set {
    my($self, $flag, $value) = @_;
    $value = 1 if(!defined($value));
    $self->set(
        ($self->get() & (0xFF - $flag)) +
        $flag * (0 + !!$value)
    );
}
sub _reset {
    my($self, $flag) = @_;
    $self->set($self->get() & (0xFF - $flag));
}

sub DESTROY{}
sub AUTOLOAD {
    (my $sub = $AUTOLOAD) =~ s/.*:://;
    my($fn, $flag) = ($sub =~ /^(.*)(.)$/);
    my $self = shift();
    no strict 'refs';
    return *{"_$fn"}->($self, $masks{$flag}, @_);
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
