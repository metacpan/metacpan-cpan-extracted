package AnyEvent::FTP;

use strict;
use warnings;
use 5.010;

# ABSTRACT: Simple asynchronous FTP client and server
our $VERSION = '0.20'; # VERSION


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::FTP - Simple asynchronous FTP client and server

=head1 VERSION

version 0.20

=head1 SYNOPSIS

 # For the client
 use AnyEvent::FTP::Client;
 
 # For the server
 use AnyEvent::FTP::Server;

=head1 DESCRIPTION

This distribution provides client and server implementations for
File Transfer Protocol (FTP) in an AnyEvent environment.  For the
specific interfaces, see L<AnyEvent::FTP::Client> and L<AnyEvent::FTP::Server>
for details.

Before each release, L<AnyEvent::FTP::Client> is tested against these FTP servers
using the C<t/client_*.t> tests that come with this distribution:

=over 4

=item Proftpd

=item wu-ftpd

=item L<Net::FTPServer>

=item vsftpd

=item Pure-FTPd

=item bftpd

=item L<AnyEvent::FTP::Server>

=back

The client code is also tested less frequently against these FTP servers:

=over 4

=item NcFTPd

=item Microsoft IIS

=back

It used to also be tested against the VMS ftp server, so it was verified to
work with it, at least at one point. However, I no longer have access to that
server.

=head1 BUNDLED FILES

This distribution comes bundled with C<ls> from the old
L<Perl Power Tools|https://metacpan.org/release/ppt> project.
This is only used on C<MSWin32> if this command is not found in
the path, as it is frequently not available on that platform

The Perl implementation of C<ls>
was written by Mark Leighton Fisher of Thomson Consumer Electronics,
I<fisherm@tce.com>.

That program is free and open software. You may use, modify,
distribute, and sell it program (and any modified variants) in any
way you wish, provided you do not restrict others from doing the same.

=head1 SEE ALSO

=over 4

=item *

L<AnyEvent::FTP::Client>

=item *

L<AnyEvent::FTP::Server>

=item *

L<Net::FTP>

=item *

L<Net::FTPServer>

=item *

L<AnyEvent>

=item *

L<RFC 959 FILE TRANSFER PROTOCOL|http://tools.ietf.org/html/rfc959>

=item *

L<RFC 2228 FTP Security Extensions|http://tools.ietf.org/html/rfc2228>

=item *

L<RFC 2640 Internationalization of the File Transfer Protocol|http://tools.ietf.org/html/rfc2640>

=item *

L<RFC 2773 Encryption using KEA and SKIPJACK|http://tools.ietf.org/html/rfc2773>

=item *

L<RFC 3659 Extensions to FTP|http://tools.ietf.org/html/rfc3659>

=item *

L<RFC 5797 FTP Command and Extension Registry|http://tools.ietf.org/html/rfc5797>

=item *

L<http://cr.yp.to/ftp.html>

=item *

L<http://en.wikipedia.org/wiki/List_of_FTP_server_return_codes>

=back

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Ryo Okamoto

Shlomi Fish

José Joaquín Atria

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017-2022 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
