package AnyEvent::FTP::Client::Site::NetFtpServer;

use strict;
use warnings;
use 5.010;
use Moo;

extends 'AnyEvent::FTP::Client::Site::Base';

# ABSTRACT: Site specific commands for Net::FTPServer
our $VERSION = '0.16'; # VERSION


# TODO add a test for this
sub version { shift->client->push_command([SITE => 'VERSION'] ) }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::FTP::Client::Site::NetFtpServer - Site specific commands for Net::FTPServer

=head1 VERSION

version 0.16

=head1 SYNOPSIS

 use AnyEvent::FTP::Client;
 my $client = AnyEvent::FTP::Client->new;
 $client->connect('ftp://netftpserver')->cb(sub {
   $client->site->net_ftp_server->version->cb(sub {
     my($res) = @_;
     # $res isa AnyEvent::FTP::Client::Response where
     # the message includes the server version
   });
 });

=head1 DESCRIPTION

This class provides the C<SITE> specific commands for L<Net::FTPServer>.

=head1 METHODS

=head2 version

 $client->site->net_ftp_server->version

Get the L<Net::FTPServer> version.

=head1 CAVEATS

Other C<SITE> commands supported by L<Net::FTPServer>, but not implemented by
this class include:

=over 4

=item SITE ALIAS

=item SITE ARCHIVE

=item SITE CDPATH

=item SITE CHECKMETHOD

=item SITE CHECKSUM

=item SITE EXEC

=item SITE IDLE

=item SITE SYNC

=back

patches that include tests are welcome.

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Ryo Okamoto

Shlomi Fish

José Joaquín Atria

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
