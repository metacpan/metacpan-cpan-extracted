
package ASP4::Mock::ClientSocket;

use strict;
use warnings 'all';

sub new {
  return bless {
    on_close  => sub { },
  }, shift;
}

sub on_close { my $s = shift; $s->{on_close} = shift }
sub close { shift->{on_close}->( ) }

1;# return true:

=pod

=head1 NAME

ASP4::Mock::ClientSocket - Mimics APR::Socket object

=head1 SYNOPSIS

  my $socket = $r->connection->client_socket

=head1 DESCRIPTION

Mimics (minimally) the L<APR::Socket> object.

=head1 PUBLIC METHODS

=head2 close( )

Internal use only.

=head1 BUGS

It's possible that some bugs have found their way into this release.

Use RT L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=ASP4> to submit bug reports.

=head1 HOMEPAGE

Please visit the ASP4 homepage at L<http://0x31337.org/code/> to see examples
of ASP4 in action.

=cut

