#############################################################################
#
# Apache::Session::Generate::DBMS;
# Generates session identifier tokens using MD5 and validate them using
# Apache::Session::DBMS extended syntax
#
# Copyright(c) 2005 Asemantics S.r.l.
# Alberto Reggiori (alberto@asemantics.com)
# Distribute under a BSD license (see LICENSE file in main dir)
#
############################################################################

package Apache::Session::Generate::DBMS;

use strict;
use vars qw($VERSION);

use Apache::Session::Generate::MD5;

$VERSION = '0.1';

sub generate {
	my $session = shift;

	&Apache::Session::Generate::MD5::generate( $session );
	};

sub validate {
	my $session = shift;

	die
		unless( $session->{isObjectPerKey} or
                	$session->{data}->{_session_id} =~ /^[a-fA-F0-9]+$/ );
	};

1;

=pod

=head1 NAME

Apache::Session::Generate::DBMS - Use MD5 to create random object IDs

=head1 SYNOPSIS

 use Apache::Session::Generate::DBMS;
 
 $id = Apache::Session::Generate::DBMS::generate();

=head1 DESCRIPTION

This module fulfills the ID generation interface of Apache::Session.  The
IDs are generated using a two-round MD5 of a random number, the time since the
epoch, the process ID, and the address of an anonymous hash.  The resultant ID
number is highly entropic on Linux and other platforms that have good
random number generators.  You are encouraged to investigate the quality of
your system's random number generator if you are using the generated ID
numbers in a secure environment.

This module can also examine session IDs to ensure that they are, indeed,
session ID numbers and not evil attacks.  The reader is encouraged to 
consider the effect of bogus session ID numbers in a system which uses
these ID numbers to access disks and databases.

This modules takes one argument in the usual Apache::Session style.  The
argument is IDLength, and the value, between 0 and 32, tells this module
where to truncate the session ID.  Without this argument, the session ID will
be 32 hexadecimal characters long, equivalent to a 128-bit key.

The validation code has been modified to support extended object-per-key
mode for Apache::Session::DBMS module.

=head1 AUTHOR

This module was written by Alberto Reggiori <alberto@asemantics.com>

=head1 SEE ALSO

L<Apache::Session::DBMS>
