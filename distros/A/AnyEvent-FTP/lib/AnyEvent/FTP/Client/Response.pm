package AnyEvent::FTP::Client::Response;

use strict;
use warnings;
use 5.010;
use base qw( AnyEvent::FTP::Response );

# ABSTRACT: Response class for asynchronous ftp client
our $VERSION = '0.16'; # VERSION


sub get_address_and_port
{
  return ("$1.$2.$3.$4", $5*256+$6) if shift->{message}->[0] =~ /\((\d+),(\d+),(\d+),(\d+),(\d+),(\d+)\)/;
  return;
}


sub get_dir
{
  if(shift->{message}->[0] =~ /^"(.*)"/)
  {
    my $dir = $1;
    $dir =~ s/""/"/;
    return $dir;
  }
  return;
}


sub get_file
{
  return shift->{message}->[0] =~ /^FILE: (.*)/i ? $1 : ();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::FTP::Client::Response - Response class for asynchronous ftp client

=head1 VERSION

version 0.16

=head1 DESCRIPTION

Instances of this class get sent to condition variables returned by
commands in L<AnyEvent::FTP::Client>.

=head1 SUPER CLASS

L<AnyEvent::FTP::Response>

=head1 METHODS

=head2 get_address_and_port

 my($ip, $port) = $res->get_address_and_port

This method is used to parse the response to the C<PASV> command to extract the IP address
and port number.

=head2 get_dir

 my $dir = $res->get_dir

This method is used to extract the path from  a response to the C<PWD> command.
It returns the path as a simple string.

=head2 get_file

 my $filename = $res->get_file;

Returns the filename from a response to the C<STOU> command.

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
