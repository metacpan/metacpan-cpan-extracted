
package Apache::GopherHandler;
use strict;
use warnings;

our $VERSION = 0.1;

use Apache::Connection ();
use APR::Socket ();
use Apache::Const -compile => 'OK';
use Gopher::Server::ParseRequest;
#use Gopher::Server::RequestHandler::File;
use Apache::GopherHandler::TiedSocket;

my ( $doc_root,     $server,     $port ) = 
   ( '/noexists/',  'localhost', 70,   );
my ( $handler ) = 'Gopher::Server::RequestHandler::File';

(    $doc_root, $handler, $server, $port ) = 
	map $Apache::GopherHandler::Config{$_}, 
  qw( doc_root   handler   server   port );


# A little sanity checking
eval " require $handler ";
die "Couldn't load a handler named '$handler': $@\n" if $@;

die "No directory '$doc_root'\n" unless -d $doc_root;


sub handler 
{
	my $c = shift;
	my $socket = $c->client_socket;

	my $request_str = '';
	while(1) {
		my $rlen = 1024;
		$socket->recv( my $buff, $rlen );

		last if $rlen <= 0;
		$request_str .= $buff;
		last if $buff =~ /[\r\n]+$/;
	}

	$request_str =~ tr/\r\n//d;
	my $request = Gopher::Server::ParseRequest->parse( $request_str );
	my $handler = $handler->new({ 
		root => $doc_root, 
		host => $server, 
		port => $port, 
	});
	my $response = $handler->process( $request );
	tie *OUT, 'Apache::GopherHandler::TiedSocket' => $socket;
	$response->print_to( *OUT );

	return Apache::OK;
}

1;
__END__


=head1 NAME 

  Apache::GopherHandler - Gopher protocol implementation for Apache2

=head1 SYNOPSIS 

 # In your Apache2 configuration
 <VirtualHost _default_:70>
 	DocumentRoot /home/www/data/gopher
 	
 	<Perl>
 		$Apache::GopherHandler::Config{doc_root} = '/home';
 		$Apache::GopherHandler::Config{server}   = 'localhost';
 		$Apache::GopherHandler::Config{port}     = 70;
 		$Apache::GopherHandler::Config{handler}  =
 			'Gopher::Server::RequestHandler::File';
 	</Perl>
 	PerlModule                    Apache::GopherHandler
 	PerlProcessConnectionHandler  Apache::GopherHandler
 </VirtualHost>

=head1 DESCRIPTION 

One of the earliest goals stated in the Gopher Manifesto 
(L<http://27.org/gopher-manifesto/>) was to have an Apache plugin that 
would run a Gopher server.  So here it is.

This requires Apache2/mod_perl.  Sorry.  The first version of Apache 
is too HTTP-centric.  In Apache2, the project moved twards a more generalized 
server that was modular enough to support other protocols.  Without that, 
making Gopher available on Apache servers would have been impossible, or at 
least very difficult.

For the moment, this isn't a very full-featured server.  If you want a 
stand-alone Gopher server, you're probably better off using PyGopherd 
(L<http://gopher.quux.org:70/devel/gopher/Downloads/pygopherd>).  If you 
want to convert an existing Apache2 server into something that can 
support Gopher and you don't care about (or can wait for) some fancier 
features, then this will work fine.

This relies on the Gopher::Server module to take care most of the 
implementation details of the protocol.  Apache::GopherHandler provides the 
glue between that module and Apache.

=head1 CONFIGURATION

The best way to run Apache::GopherHandler is inside an Apache <VirtualHost>.  
Actual configuration is done either inside a <Perl> directive or your 
Apache startup file.  This is done by accessing the hash 
C<%Apache::GopherHandler::Config>.  Keys can be specified here that will 
be passed to the C<Gopher::Server::Requesthandler> you specify in the 
C<handler> key.  Currently, only C<Gopher::Server::RequestHandler::File> 
is supported (but this will change).

At a minimum, the following keys are needed:

=head2 handler

The C<Gopher::Server::RequestHandler> class to use.  Default: 
C<Gopher::Server::RequestHandler::File>

=head2 server 

The hostname of the server.  Default: localhost

=head2 port

The TCP port of the server.  Make sure your <VirtualHost> directive 
specifies this port and the Apache C<Listen> option is set to listen 
on this port.  Default: 70

=head2 doc_root 

The root of the Gopher server on your file system.  Default: /noexists/

=head1 BUGS 

Yes.

=head1 AUTHOR

 Timm Murray
 CPAN ID: TMURRAY
 E-Mail: tmurray@cpan.org
 Homepage: http://www.wumpus-cave.net

=head1 LICENSE

Apache::GopherHandler
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


