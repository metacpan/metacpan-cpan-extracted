# $Id: Register8R.pm,v 1.2 2008/02/22 02:08:08 drhyde Exp $

package CPU::Emulator::Z80::Register8R;

use strict;
use warnings;

use vars qw($VERSION $AUTOLOAD);

use base qw(CPU::Emulator::Z80::Register8);

$VERSION = '1.0';

=head1 NAME

CPU::Emulator::Z80::Register8R - the R register for a Z80

=head1 DESCRIPTION

This class is a ...::Register8 with a weird inc() method

=head1 METHODS

It has the same methods as its parent, with the following changes:

=head2 inc

The inc() method operates on the least significant 7 bits of the
register only.

=cut

sub inc {
    my $self = shift;
    my $r = $self->get();
    $self->set(($r & 0b10000000) | (($r + 1) & 0b01111111));
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
