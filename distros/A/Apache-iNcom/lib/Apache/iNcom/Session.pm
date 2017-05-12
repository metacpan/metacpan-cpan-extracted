#
#    Session.pm - Apache::Session implementation for iNcom application.
#
#    This file is part of Apache::iNcom.
#
#    Author: Francis J. Lacoste <francis.lacoste@iNsu.COM>
#
#    Copyright (C) 1999 Francis J. Lacoste, iNsu Innovations
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
package Apache::iNcom::Session;

use strict;
use vars qw(@ISA $VERSION);

BEGIN {
    ($VERSION) = '$Revision: 1.5 $' =~ /Revision: ([\d.]+)/;
    @ISA = qw(Apache::Session);
}

use Digest::MD5 qw( md5_hex );

use Apache::Session;
use Apache::iNcom::SessionLocker;
use Apache::Session::DBIBase64Store;

use Symbol;

my $HAVE_RANDOM_DEV = -c "/dev/urandom";
warn __PACKAGE__ . ": no random device found: using insecure session id\n"
  unless $HAVE_RANDOM_DEV;
my $random_dev = gensym;

sub get_object_store {
    my $self = shift;

    return new Apache::Session::DBIBase64Store $self;
}

sub get_lock_manager {
    my $self = shift;

    return new Apache::iNcom::SessionLocker;
}

# We want longer session id than the 16 characters of
# Apache::Session
# We override the method
sub generate_id {
    # Collision generates error on insert. So we don't
    # really care here if we generate same if twice. 
    # Besides with the random device, this probability
    # is really low.
  SAFE_ID:
    {
	last SAFE_ID unless $HAVE_RANDOM_DEV;
	open $random_dev, "/dev/urandom" or last SAFE_ID;
	my $session_id;
	read $random_dev, $session_id, 16 or last SAFE_ID;
	close $random_dev;

	return unpack( "H*", $session_id );
    }

    # If we got here, this system doesn't have
    # a random device, so we fudge.

    # How much real entropy we got in this ???
    return md5_hex( time(), {}, rand(), $$, 'foo' );
}

1;

__END__

=pod

=head1 NAME

Apache::iNcom::Session - Apache::Session implementation for Apache::iNcom

=head1 SYNOPSIS

use Apache::iNcom::Session;

=head1 DESCRIPTION

This is a subclass of Apache::Session used by the iNcom framework.
This Apache::Session implementation used the DBIBase64Store and NullLocker
for handling session persistence.

The other special thing about this implementation is that session IDs
are 128bits long and generated using the /dev/urandom device if
available.

This is a security feature to make session id very hard to guess.

=head1 AUTHOR

Copyright (c) 1999 Francis J. Lacoste and iNsu Innovations Inc.
All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

=head1 SEE ALSO

Apache::iNcom(3) Apache::Session(3) Apache::Session::DBIBase64Store(3)
Apache::Session::NullLocker(3)

=cut
