###############################################################################
#
# $Id: Prot.pm,v 1.8 1998/11/10 05:09:56 paulg Exp $
#
# Copyright (c) 1997-98 Paul Gampe. All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify it 
# under the same terms as Perl itself. See COPYRIGHT section below.
# 
###############################################################################

package Authen::Prot;

use strict;
use vars qw($VERSION @ISA @EXPORT);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter AutoLoader DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = do { my @r=(q$Revision: 1.8 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r};

bootstrap Authen::Prot $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Authen::Prot - Perl extension for accessing protected password database

=head1 SYNOPSIS

  use Authen::Prot;

  Authen::Prot::setprpwent();

  $pw = Authen::Prot->getprpwent();

  $pw = Authen::Prot->getprpwuid(0);

  $pw = Authen::Prot->getprpwnam('daemon');

  print "$pw->ufld_fd_name\n";

  $pw->ufld_fd_slogin(time);

  $pw->putprpwnam();

  $crypt = Authen::Prot::bigcrypt('test', 'test'); # not avail on DEC/OSF

  Authen::Prot::endprpwent();

=head1 DESCRIPTION

The Authen::Prot module provides access to the protected password
database via the getprpwent, getprpwuid, getprpwnam, getprpwaid,
setprpwent, endprpwent, and putprpwnam system calls available on those
Unix systems using the Protected Password database written by SecureWare
Inc. (c).

=head2 METHODS

The availability of some of the methods below will depend on how the
Protected Password database has been implemented on your system.

=over 4

=item $crypt = Authen::Prot::bigcrypt($key, $salt)

Encrypted $key using the bigcrypt(3) system call if available and
returns the result. Not available on DEC/OSF, via this package yet.

=item $pw = Authen::Prot::getprpwent()

This method returns a reference to a blessed Authen::Prot object.  You
may then use this reference to retrieve values of fields in the
protected password database. When this method is first called it returns
the first entry in the database, on each subsequent call it returns the
next entry. See getprpwent(3) for further information on which records
are returned.  

=item $pw = Authen::Prot::getprpwuid($uid)

This method returns a reference to a blessed Authen::Prot object if an
entry with a uid of that passed is found, otherwise it will return
C<undef>.  You may then use this reference to retrieve values of fields
in the protected password database.  See getprpwuid(3) for further
information on how records are returned.  

=item $pw = Authen::Prot::getprpwaid($aid)

This method returns a reference to a blessed Authen::Prot object if an
entry with a aid of that passed is found, otherwise it will return
C<undef>.  You may then use this reference to retrieve values of fields
in the protected password database.  See getprpwaid(3) for further
information on how records are returned.  

=item $pw = Authen::Prot::getprpwnam($name)

This method returns a reference to a blessed Authen::Prot object if an
entry with a login name of that passed is found, otherwise it will
return C<undef>.  You may then use this reference to retrieve values of
fields in the protected password database.  See getprpwnam(3) for
further information on how records are returned.  

=item Authen::Prot::setprpwent()

Calling setprpwent effectively rewinds the pointer into the protected
password databases so that a subsequent call to getprpwent will return
the first record.  See setprpwent(3) for further information on the
function of this method.

=item Authen::Prot::endprpwent()

Calling endprpwent effectively closes the protected password database.
See endprpwent(3) for further information on the function of this method.

=item $pw->putprpwnam()

This method commits a Prot object to the protected password database.
Setting $pw->uflg_fg_name to 0 will delete the corresponding entry.
See putprpwnam(3) for further information on the function of this
method.

=item $pw->pr_struct_field_name() / $pw->pr_struct_field_name($value)

The fields available from the methods described above, depend on the
definition of the pr_struct structure in the F</usr/include/prot.h> on
your system, and the information available I have to interpret them.
This module will attempt to parse your F<prot.h> file and generate a XS
function for each field available on your system.  The pr_struct
typically consists of four structures given the name of ufld, sfld, uflg
and sflg for User fields, System fields, User flags and System flags
respectively.

To allow for the syntax differences between C and Perl the field names
have been re-written replacing the struct C<.> with a C<_> in Perl.  For
example the User field login name would be referenced 

in C as:

	ufld.fd_name 

and in Perl as:

	$pw->ufld_fd_name

=back

=head1 COPYRIGHT

The Protected Password database library by SecureWare Inc. (c) is
classified as containing Confidential information so I am unable to
include the field descriptions in this document.  Please refer to the
man pages referenced below and to the F</usr/include/prot.h> header file
for further information.

=head1 EXAMPLES

The F<test.pl> file provides examples of the methods available via this
extension common to most platforms.

=head1 AUTHOR

Paul Gampe <paulg@apnic.net>.  

I would appreciate it if you could send me an email if you starting
using this package, so I can notify you of updates, and get an idea of
what platforms it is compatible with.

=head1 FILES

F</usr/include/prot.h>

=head1 COPYRIGHT

Copyright (c) 1997-98 Paul Gampe. All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

IN NO EVENT SHALL THE AUTHORS OR DISTRIBUTORS BE LIABLE TO ANY PARTY
FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
ARISING OUT OF THE USE OF THIS SOFTWARE, ITS DOCUMENTATION, OR ANY
DERIVATIVES THEREOF, EVEN IF THE AUTHORS HAVE BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE. 

THE AUTHORS AND DISTRIBUTORS SPECIFICALLY DISCLAIM ANY WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND
NON-INFRINGEMENT. THIS SOFTWARE IS PROVIDED ON AN ``AS IS'' BASIS, AND
THE AUTHORS AND DISTRIBUTORS HAVE NO OBLIGATION TO PROVIDE
MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS. 

=head1 SEE ALSO

getprpwent(3), getprpwuid(3), getprpwnam(3), getprpwaid(3),
setprpwent(3), endprpwent(3), putprpwnam(3), perl(1).

=cut
