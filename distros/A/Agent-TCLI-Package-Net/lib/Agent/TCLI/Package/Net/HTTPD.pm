package Agent::TCLI::Package::Net::HTTPD;
#
# $Id: HTTPD.pm 74 2007-06-08 00:42:53Z hacker $
#
=pod

=head1 NAME

Agent::TCLI::Package::Net::HTTPD

=head1 SYNOPSIS

From within a TCLI Agent session:

httpd uri add regex=^/good/.* response=OK200

=head1 DESCRIPTION

This module provides a package of commands for the TCLI environment. Currently
one must use the TCLI environment (or browse the source) to see documentation
for the commands it supports within the TCLI Agent.

This package starts a specialized HTTPD on the local system. It does not
return files but does return 404 or 200 values for user defined URLs. It can
also be set to completely ignore a request. URLs may be defined with
regular expressions.

It can also log directly to the log being monitored by the Tail command
in memory with no disk writes.

=head1 INTERFACE

This module must be loaded into a Agent::TCLI::Control by an
Agent::TCLI::Transport in order for a user to interface with it.

=cut

use warnings;
use strict;

use Object::InsideOut qw(Agent::TCLI::Package::Base);

use POE;
use POE::Component::Server::SimpleHTTP;
use HTTP::Request::Common qw(GET POST);
use Agent::TCLI::Command;
use Agent::TCLI::Parameter;

require FormValidator::Simple;
FormValidator::Simple->import('NetAddr::IP');

our $VERSION = '0.030.'.sprintf "%04d", (qw($Id: HTTPD.pm 74 2007-06-08 00:42:53Z hacker $))[2];

=head2 ATTRIBUTES

The following attributes are accessible through standard <attribute>
methods unless otherwise noted.

These attrbiutes are generally internal and are probably only useful to
someone trying to enhance the functionality of this Package module.

=over

=item ports

A hash of ports with HTTPD listeners running
B<ports> will only contain hash values.

=cut

my @ports			:Field
					:Type('hash')
					:Arg('name'=>'ports', 'default'=>{ } )
					:Acc('ports');

=item handlers

The array of handlers for the SimpleHTTP server.
B<handlers> will only contain Array values.

=cut
my @handlers		:Field
					:Type('Array')
					:All('handlers');

=back

=head2 METHODS

Most of these methods are for internal use within the TCLI system and may
be of interest only to developers trying to enhance TCLI.

=over

=item new ( hash of attributes )

Usually the only attributes that are useful on creation are the
verbose and do_verbose attrbiutes that are inherited from Agent::TCLI::Base.

=cut

sub _preinit :PreInit {
	my ($self,$args) = @_;

	$args->{'name'} = 'tcli_httpd';

	$args->{'session'} = POE::Session->create(
      object_states => [
          $self => [qw(
          	_start
          	_stop
          	_shutdown
          	_default
          	_child

			establish_context
			settings
			show
			spawn
			stop
			uri

			OK200
			NA404
			BeGone
			Log

			)],
      ],
      'heap' => $self,
	);
}

sub _init :Init {
	my $self = shift;

	$self->LoadYaml(<<'...');
---
Agent::TCLI::Parameter:
  name: address
  constraints:
    - NETADDR_IP4HOST
  help: An address to listen on
  manual: >
    The IP address for the HTTPD to listen on. Must already be configured
    on the system.
  type: Param
---
Agent::TCLI::Parameter:
  name: port
  constraints:
    - UINT
    -
      - BETWEEN
      - 1
      - 65535
  default: 8080
  help: A port to listen on
  manual: >
    Port sets the port used for the HTTPD to receive requests on.
    It must not already be in use by another process. If is is less
    than 1024, then the script must already be running as root or
    the HTTPD will fail to start. Port defaults to 8080.
  type: Param
  class: numeric
---
Agent::TCLI::Parameter:
  name: hostname
  constraints:
    - ASCII
  help: A hostname that the server will respond back with.
  manual: >
    The host nmae is the name the server will respond back with. It
    does not have to be the correct DNS name for the server. It will default
    to Sys::Hostname.
  type: Param
---
Agent::TCLI::Parameter:
  name: regex
  constraints:
    - ASCII
  help: A regular expression pattern
  manual: >
    The regex should be a string that can be evaluated inside a regular
    expression. It should not include the delimeters or be provided in
    qr() form.
  type: Param
---
Agent::TCLI::Parameter:
  name: logging
  help: Turn on logging to the Tail command line queue
  manual: >
    The logging switch turns on logging to the line queue monitored by the
    Tail command. This does not write to logs disk. One may then set up
    Tail tests for specific URI's to determine exactly which ones got through.
    To turn off, use no_logging.
    By default the line queue will only hold 10 lines so memory cannot
    accidentally be exhausted.
  type: Switch
---
Agent::TCLI::Parameter:
  name: response
  aliases: resp
  constraints:
    - ASCII
    -
      - IN_ARRAY
      - OK200
      - NA404
      - BeGone
  default: OK200
  help: The desired response
  manual: >
    The response must be one of the pre-defined responses. Currently these are:
    OK200, NA404, BeGone.
    The default is OK200.
  type: Param
---
Agent::TCLI::Parameter:
  name: handlers
  help: Show the active handlers
  manual: >
    The handlers are stored in a format compatible with PoCo::Server::SimpleHTTP.
    The DIR is the regex and the EVENT is the response.
  type: Switch
---
Agent::TCLI::Parameter:
  name: ports
  help: Show the active HTTPD ports
  manual: >
    This will show the active httpd ports.
  type: Switch
---
Agent::TCLI::Command:
  name: httpd
  call_style: session
  command: tcli_httpd
  contexts:
    ROOT: httpd
  handler: establish_context
  help: simple http web server
  manual: >
    httpd provides a simple web server that can respond to and log requests.
    By default it responds with a Status code 404 to all requests. One may add
    a select few other status code responses using regular expression pattern
    matching if desired. One cannot change content, only status codes.
    Httpd is useful for network testing situations where the response codes
    are being monitored by the network.
  topic: net
  usage: httpd spawn port=8080
---
Agent::TCLI::Command:
  name: spawn
  call_style: session
  command: tcli_httpd
  contexts:
    httpd: spawn
  handler: spawn
  help: starts an http server on a particular port
  manual: >
    The spawn command starts an httpd listener on a particular port. One
    may enable more than one httpd listener so long as they are
    using different ports.
    The script must have root priviledges if the port is less than 1024.
  parameters:
    port:
    address:
    hostname:
  required:
    port:
  topic: net
  usage: httpd spawn port=8080
---
Agent::TCLI::Command:
  name: stop
  call_style: session
  command: tcli_httpd
  contexts:
    httpd: stop
  handler: stop
  help: Stops a running http server on a particular port
  manual: >
    The stop command stops an httpd listener running on the specified port. It
    will return an error if the port cannot be found in the list of servers
    running.
  parameters:
    port:
  required:
    port:
  topic: net
  usage: httpd stop port=8080
---
Agent::TCLI::Command:
  name: uri
  call_style: session
  command: tcli_httpd
  contexts:
    httpd: uri
  handler: establish_context
  help: adds or removes a uri regex from the httpd
  manual: >
    The httpd can be set to respond to different uri queries with this command.
  topic: net
  usage: httpd uri add regex=^/good/.* response=OK200
---
Agent::TCLI::Command:
  name: uri_add
  call_style: session
  command: tcli_httpd
  contexts:
    httpd:
      uri: add
  handler: uri
  help: adds a uri regex from the httpd
  manual: >
    Adds a uri regular expression and the desired response to the handler table.
    Regular expressions are applied in order of their entry into the table and
    the first match is the one that wins. One cannot delete the default
    catch-all response, but one can add a different catch-all response in
    front of it using regex=.*
    One cannot add uri's while a HTTPD server is running. The Agent will crash.
  parameters:
    regex:
    response:
  required:
    regex:
  topic: net
  usage: httpd uri add regex=^/good/.* response=OK200
---
Agent::TCLI::Command:
  name: uri_delete
  call_style: session
  command: tcli_httpd
  contexts:
    httpd:
      uri: delete
  handler: uri
  help: removes a uri regex from the httpd
  manual: >
    This command removes an existing regex from the uri handler list.
    It must match exactly to the existing uri regex that was added. It
    does not allow removal of the default NA404 response.
  parameters:
    regex:
  required:
    regex:
  topic: net
  usage: httpd uri add regex=^/good/.* response=OK200
---
Agent::TCLI::Command:
  name: set
  call_style: session
  command: tcli_httpd
  contexts:
    httpd: set
  handler: settings
  help: adjust default settings
  parameters:
    logging:
    address:
    port:
    hostname:
    regex:
    response:
  topic: net
  usage: httpd set hostname=example.com
---
Agent::TCLI::Command:
  name: show
  call_style: session
  command: tcli_httpd
  contexts:
    httpd: show
  handler: show
  help: show tail default settings and state
  parameters:
    logging:
    address:
    port:
    hostname:
    regex:
    response:
    handlers:
    ports:
  topic: testing
  usage: httpd show settings
...

}

sub _start {
	my ($kernel,  $self,  $session) =
      @_[KERNEL, OBJECT,   SESSION];
	$self->Verbose("_start: tcli httpd starting");

	# are we up before OIO has finished initializing object?
	if (!defined( $self->name ))
	{
		$kernel->yield('_start');
		return;
	}

	# There is only one command object per TCLI
    $kernel->alias_set($self->name);

	$self->handlers( [
			{
				'DIR'		=>	'.*',
				'SESSION'	=>	$self->name,
				'EVENT'		=>	'NA404',
			},
	] ) unless defined($self->handlers);

	$self->Verbose("_start Dump ".$self->dump(1),3);

}

sub _shutdown :Cumulative {
    my ($kernel,  $self, $session) =
      @_[KERNEL, OBJECT,  SESSION];
	$self->Verbose($self->name.':_shutdown:');

	foreach my $port ( keys %{ $self->ports } )
	{
		$self->Verbose("_shutdown: $port");
		$kernel->post( 'HTTPD'.$port  , 'SHUTDOWN' );
	}
	return ('_shutdown '.$self->name )
}

sub _stop {
    my ($kernel,  $self,) =
      @_[KERNEL, OBJECT,];
	$self->Verbose("_stop: ".$self->name." stopping",2);
}

=item spawn

This POE event handler executes the spawn command to start a new HTTPD listener.

=cut

sub spawn {
    my ($kernel,  $self, $sender, $request, ) =
      @_[KERNEL, OBJECT,  SENDER,     ARG0, ];

	my $txt = '';
	my $param;
	my $command = $request->command->[0];
	my $cmd = $self->commands->{$command};

	return unless ( $param = $cmd->Validate($kernel, $request, $self) );

	$self->Verbose("spawn: param dump",4,$param);

	# is one running already?
	if (exists( $self->ports->{ $param->{'port'} } ))
	{
		$self->Verbose("spawn: ".$param->{'port'}." already running");
		$request->Respond($kernel,"HTTPD server on port ".
			$param->{'port'}." already running",400);
		return;
	}

	# Start the server!
	$self->ports->{ $param->{'port'} } =
		POE::Component::Server::SimpleHTTP->new(
		'ALIAS'		=>	'HTTPD'.$param->{'port'},
		'ADDRESS'	=>	defined($param->{'address'})
			? $param->{'address'}
			: $sender->get_heap->local_address,
		'PORT'		=>	$param->{'port'},
		'HOSTNAME'	=>	defined($param->{'hostname'})
			? $param->{'hostname'}
			: '',
		'HANDLERS'	=>	$self->handlers,

#		'LOGHANDLER' => {
#				'SESSION' => $self->name,
#				'EVENT'   => 'Log',
#		},

		# In the testing phase...
#		'SSLKEYCERT'	=>	[ 'public-key.pem', 'public-cert.pem' ],
	);

	unless (defined( $self->ports->{ $param->{'port'} } ) )
	{
		 $request->Respond($kernel,'Unable to create the HTTPD Server',400);
		 return;
	}

	# store the $sender for later use.
	$self->SetWheelKey($param->{'port'}, 'control' => $sender );

	$request->Respond($kernel,'HTTPD Started on port '.$param->{'port'},200);
}

=item stop

This POE Event handler executes the stop command to shutdown a HTTPD listener.

=cut

sub stop {
    my ($kernel,  $self, $sender, $request, ) =
      @_[KERNEL, OBJECT,  SENDER,     ARG0, ];

	my $txt = '';
	my $param;
	my $command = $request->command->[0];
	my $cmd = $self->commands->{$command};

	return unless ( $param = $cmd->Validate($kernel, $request, $self) );

	$self->Verbose("spawn: param dump",4,$param);

	unless (defined( $self->ports->{ $param->{'port'} } ) )
	{
		 $request->Respond($kernel,'Unable to locate the HTTPD Server',404);
		 return;
	}

	$kernel->post( 'HTTPD'.$param->{'port'}  , 'SHUTDOWN' );

	# remove the stored control for this server
	$self->SetWheelKey( $param->{'port'} , 'control' );

	delete( $self->ports->{ $param->{'port'} } );

	$request->Respond($kernel,'HTTPD Stopped on port '.$param->{'port'},200);
}

=item uri

This POE Event handler excecutes the uri add and uri delete commands.

=cut

sub uri {
    my ($kernel,  $self, $sender, $request, ) =
      @_[KERNEL, OBJECT,  SENDER,     ARG0, ];

	my $txt = '';
	my $code;
	my $param;
	my $command = $request->command->[0];
	my $cmd = $self->commands->{'uri_'.$command};

	return unless ( $param = $cmd->Validate($kernel, $request, $self) );

	if ( $command eq 'add' )
	{
		my $last = $self->pop_handlers;
		$self->push_handlers(
			{
				'DIR'		=>	$param->{'regex'},
				'SESSION'	=>	$self->name,
				'EVENT'		=>	$param->{'response'},
			},
			$last
		);
		$txt = 'uri added';
		$code = 200;
	}
	elsif ( $command eq 'delete' )
	{
		my $i = 0;
		$txt = "regex not found, delete failed";
		$code = 404;
		# This will loop over the handlers and removel ALL matches.
		foreach my $handler ( @{$self->handlers} )
		{
			if ( $param->{'regex'} eq $handler->{'DIR'} &&
				$i != $self->depth_handlers ) # Don't remove last one, ever.
			{
				my $goner = splice( @{$self->handlers},$i,1 );
				$txt .= "regex ".$goner->{'DIR'}." with response ".
					$goner->{'EVENT'}." deleted \n";
				$code = 200;
			}
			$i++;
		}
	}

	$request->Respond($kernel,$txt,$code);
}

=item BeGone

This POE Event handler is used as a target event for URIs. It simply drops the
connection. It will log the conenction if logging is turned on.

=cut

sub BeGone {
	# ARG0 = HTTP::Request object, ARG1 = HTTP::Response object,
	# ARG2 = the DIR that matched
	my ($kernel, $self, $request, $response, $dirmatch ) =
	  @_[KERNEL, OBJECT, ARG0 .. ARG2 ];

	my $port = $response->connection->local_port;

	# Do our stuff to HTTP::Response
	$response->code( 0 );

	$kernel->call($self->name => 'Log' => $request, $response ) if $self->logging;

	$kernel->post( 'HTTPD'.$port  , 'CLOSE', $response );
}

=item OK200

This POE Event handler is used as a target event for URIs. It will
send an HTTP response code of 200 with the content 'OK'.
It will log the conenction if logging is turned on.

=cut

sub OK200 {
	# ARG0 = HTTP::Request object, ARG1 = HTTP::Response object,
	# ARG2 = the DIR that matched
	my ($kernel, $self, $request, $response, $dirmatch ) =
	  @_[KERNEL, OBJECT,    ARG0,      ARG1,      ARG2 ];

	my $port = $response->connection->local_port;

	# Do our stuff to HTTP::Response
	$response->code( 200 );
	$response->content( 'OK' );

	$kernel->call( $self->name => 'Log' => $request, $response ) if $self->logging;

	$kernel->post('HTTPD'.$port, 'DONE', $response );
}

=item NA404

This POE Event handler is used as a target event for URIs. It will
send an HTTP response code of 404 with an error message.
It will log the conenction if logging is turned on.

=cut

sub NA404 {
	# ARG0 = HTTP::Request object, ARG1 = HTTP::Response object,
	# ARG2 = the DIR that matched
	my ($kernel, $self, $request, $response, $dirmatch ) =
	  @_[KERNEL, OBJECT, ARG0 .. ARG2 ];

	my $port = $response->connection->local_port;

	# Check for errors
	if ( ! defined $request ) {
		$_[KERNEL]->post( 'HTTPD'.$port, 'DONE', $response );
		return;
	}

	# Do our stuff to HTTP::Response
	$response->code( 404 );
	$response->content( "Hi visitor from " . $response->connection->remote_ip.
		", Page not found -> '" . $request->uri->path . "'" );

	$kernel->call($self->name => 'Log' => $request, $response ) if $self->logging;

	$kernel->post('HTTPD'.$port, 'DONE', $response );
}

=item Log

This POE Event handler is used internally to provide the logging. It sends
the time, remote ip:port, local ip:port, uri and optionally the SSL cipher
to the Tail session.

=back

=cut

sub Log {
	my ($kernel,  $self, $request, $response) =
	  @_[KERNEL, OBJECT, ARG0    , ARG1];

	$self->Verbose("Log: request(".$request->uri);
	my $port = $response->connection->local_port;

	my $log;
	# If the request was malformed, $request = undef
	if ( $request )
	{
		 $log = join (' ',
		 		time(),
		 		$response->connection->remote_ip.':'.$response->connection->remote_port,
		 		$response->connection->local_ip.':'.$port,
		 		$response->code,
		 		$request->uri,
		 		$response->connection->ssl ? $response->connection->sslcipher : '',
		 	)."\n";
	}
	else
	{
		 $log = join (' ',
		 		time(),
		 		$response->connection->remote_ip.':'.$response->connection->remote_port,
		 		$response->connection->local_ip.':'.$port,
		 		$response->code,
				'Bad request',
		 		$response->connection->ssl ? $response->connection->sslcipher : '',
			)."\n";
	}

	# In the future we'll need to resolve port to control to send to correct tail
	my $control = $self->GetWheelKey( $port, 'control');

	$kernel->post('tcli_tail', 'Append', $log );
	return;
}

1;
#__END__

=head3 INHERITED METHODS

This module is an Object::InsideOut object that inherits from Agent::TCLI::Package::Base. It
inherits methods from both. Please refer to their documentation for more
details.

=head1 AUTHOR

Eric Hacker	 E<lt>hacker at cpan.orgE<gt>

=head1 BUGS

One cannot add uri's while a HTTPD server is running.

SHOULDS and MUSTS are currently not enforced.

Test scripts not thorough enough.

Probably many others.

=head1 LICENSE

Copyright (c) 2007, Alcatel Lucent, All rights resevred.

This package is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=cut