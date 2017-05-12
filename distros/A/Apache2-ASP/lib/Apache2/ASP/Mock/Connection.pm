
package Apache2::ASP::Mock::Connection;

use strict;
use warnings 'all';
use Apache2::ASP::Mock::ClientSocket;


#==============================================================================
sub new
{
  my ($class) = @_;
  
  my $s = bless {
    aborted => 0,
  }, $class;
  $s->{client_socket} = Apache2::ASP::Mock::ClientSocket->new( connection => $s );
  
  return $s;
}# end new()


#==============================================================================
sub aborted
{
  my ($s) = shift;
  @_ ? $s->{aborted} = shift : $s->{aborted};
}# end aborted()


#==============================================================================
sub client_socket
{
  $_[0]->{client_socket};
}# end client_socket()


#==============================================================================
sub DESTROY
{
  my $s = shift;
  undef(%$s);
}# end DESTROY()

1;# return true:


=pod

=head1 NAME

Apache2::ASP::Mock::Connection - Mimics the Apache2::Connection object

=head1 SYNOPSIS

  my $conn = $Response->context->connection;
  unless( $conn->aborted )
  {
    $conn->client_socket->close();
  }# end unless()

=head1 DESCRIPTION

This package mimics the L<Apache2::Connection> object in a normal mod_perl2 environment,
and is used by L<Apace2::ASP::API>.

=head1 PUBLIC PROPERTIES

=head2 aborted

Read-only.

Returns true or false, depending on whether the current connection is aborted.

=head2 client_socket

Returns the current L<Apache2::ASP::Mock::ClientSocket> object.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Apache2-ASP> to submit bug reports.

=head1 HOMEPAGE

Please visit the Apache2::ASP homepage at L<http://www.devstack.com/> to see examples
of Apache2::ASP in action.

=head1 AUTHOR

John Drago <jdrago_999@yahoo.com>

=head1 COPYRIGHT

Copyright 2008 John Drago.  All rights reserved.

=head1 LICENSE

This software is Free software and is licensed under the same terms as perl itself.

=cut


