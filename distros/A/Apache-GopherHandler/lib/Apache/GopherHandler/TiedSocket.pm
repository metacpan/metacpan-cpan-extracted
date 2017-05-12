
package Apache::GopherHandler::TiedSocket;
use strict;
use warnings;


sub TIEHANDLE 
{
	my ($class, $socket) = @_;
	bless [ $socket ], $class;
}

sub PRINT 
{
	my ($self, @to_print) = @_;
	my $socket = $self->[0];

	use bytes; # Need byte length, not char length
	my $to_print = join('', @to_print);
	$socket->send( $to_print, length $to_print );
}

sub READ 
{
	my ($self, $buf, $len) = @_;
	$self->[0]->recv( $buf, $len );
}

1;
__END__


=head1 NAME 

  Apache::TiedSocket -- Tie an APR::Socket instance to a filehandle

=head1 SYNOPSIS 

  use Apache::TiedSocket;
  my $socket; # Defined elsewhere to an APR::Socket instance
  tie *FH => 'Apache::TiedSocket' => $socket;
  
  print FH "test";
  my $in = read( FH, my $buf, 1024 );
  close(FH);

=head1 DESCRIPTION 

=head1 AUTHOR

 Timm Murray
 CPAN ID: TMURRAY
 E-Mail: tmurray@cpan.org
 Homepage: http://www.wumpus-cave.net

=head1 LICENSE

Apache::GopherHandler::TiedSocket 
Copyright (C) 2004  Timm Murray

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=cut
