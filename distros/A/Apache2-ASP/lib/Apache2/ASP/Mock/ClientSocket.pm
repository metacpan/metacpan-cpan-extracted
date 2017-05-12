
package Apache2::ASP::Mock::ClientSocket;

use strict;
use warnings 'all';
use Scalar::Util 'weaken';


#==============================================================================
sub new
{
  my ($class, %args) = @_;
  
  my $s = bless \%args, $class;
  
  weaken($s->{connection});
  return $s;
}# end new()


#==============================================================================
sub close
{
  my $s = shift;
  
  $s->{connection}->aborted( 1 );
}# end close()

1;# return true:

=pod

=head1 NAME

Apache2::ASP::Mock::ClientSocket - Mimics the APR::Socket object

=head1 SYNOPSIS

  my $socket = $Response->context->connection->client_socket;
  $socket->close();

=head1 DESCRIPTION

This package mimics the L<APR::Socket> object in a normal mod_perl2 environment,
and is used by L<Apace2::ASP::API>.

=head1 PUBLIC METHODS

=head2 close( )

Pretends to close the current connection.

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


