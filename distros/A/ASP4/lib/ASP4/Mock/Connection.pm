
package ASP4::Mock::Connection;

use strict;
use warnings 'all';
use ASP4::Mock::ClientSocket;

sub new {
  my $s = bless {
    aborted => 0,
    client_socket  => ASP4::Mock::ClientSocket->new()
  }, shift;
  $s->{client_socket}->on_close(sub {
    $s->{aborted} = 0;
  });
  
  return $s;
}

sub aborted { shift->{aborted} }
sub client_socket { shift->{client_socket} }
sub remote_addr { }

1;# return true:

=pod

=head1 NAME

ASP4::Mock::Connection - Mimic the Apache2::Connection object

=head1 SYNOPSIS

  my $connection = $r->connection;
  
  if( $connection->aborted ) {
    # The connection has been closed:
  }
  
  my $socket = $connection->client_socket;

=head1 DESCRIPTION

Minimal mimic of the L<Apache2::Connection> object.

=head1 PUBLIC PROPERTIES

=head2 aborted( )

Returns true or false, if the current connection has been aborted or not - respectively.

=head2 client_socket( )

Returns an instance of L<ASP4::Mock::ClientSocket>.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ASP4> to submit bug reports.

=head1 HOMEPAGE

Please visit the ASP4 homepage at L<http://0x31337.org/code/> to see examples
of ASP4 in action.

=cut

