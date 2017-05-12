# $Id: Register16SP.pm,v 1.1 2008/02/23 20:07:01 drhyde Exp $

package CPU::Emulator::Z80::Register16SP;

use strict;
use warnings;

use vars qw($VERSION);

use base qw(CPU::Emulator::Z80::Register16);

use CPU::Emulator::Z80::ALU;

$VERSION = '1.0';

=head1 NAME

CPU::Emulator::Z80::Register16 - a 16 bit register for a Z80

=head1 DESCRIPTION

This class implements a 16-bit register for a Z80.

=head1 METHODS

=head2 add

Add the specified value to the register, without frobbing flags

=cut

sub add {
    my($self, $op) = @_;
    $self->set($self->get() + 2);
}

=head2 sub

Subtract the specified value from the register, without frobbing flags

=cut

sub sub {
    my($self, $op) = @_;
    $self->set($self->get() - 2);
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
