package Agent::TCLI::Package::Net::HTTP;
#
# $Id: HTTP.pm 74 2007-06-08 00:42:53Z hacker $
#
=pod

=head1 NAME

Agent::TCLI::Package::Net::HTTP

=head1 SYNOPSIS

From within a TCLI Agent session:

tget url=http://example.com/bad_request resp=404

=head1 DESCRIPTION

This module provides a package of commands for the TCLI environment. Currently
one must use the TCLI environment (or browse the source) to see documentation
for the commands it supports within the TCLI Agent.

Makes standard http requests, either testing that a response code was given
or receive the response code back.

=head1 INTERFACE

This module must be loaded into a Agent::TCLI::Control by an
Agent::TCLI::Transport in order for a user to interface with it.

=cut

use warnings;
use strict;

use Object::InsideOut qw(Agent::TCLI::Package::Base);

use POE;
use POE::Component::Client::HTTP;
use POE::Component::Client::Keepalive;
use HTTP::Request::Common qw(GET POST);
use Agent::TCLI::Command;
use Agent::TCLI::Parameter;
use Getopt::Lucid qw(:all);

our $VERSION = '0.030.'.sprintf "%04d", (qw($Id: HTTP.pm 74 2007-06-08 00:42:53Z hacker $))[2];

=head2 ATTRIBUTES

The following attributes are accessible through standard <attribute>
methods unless otherwise noted.

These attrbiutes are generally internal and are probably only useful to
someone trying to enhance the functionality of this Package module.

=over

=cut

#my @session 	:Field
#				:Weak
#				:Type('POE::Session');

=item poco_cm

A POE connection manager session.
B<cm> will only accept POE::Component::Client::Keepalive type values.

=cut

my @poco_cm			:Field
					:All('poco_cm')
					:Type('POE::Component::Client::KeepaliveRaw' );

=item poco_http

The POE http client.
B<poco_http> will only accept POE::Component::Client::HTTP type values.

=cut
my @poco_http		:Field
					:All('poco_http')
					:Type('POE::Component::Client::HTTPRaw' );

=item user_agents

An array of user_agents to use.
B<user_agents> will only accept ARRAY type values.

=cut
my @user_agents		:Field
					:All('user_agents')
					:Type('ARRAY' );

=item cookie_jar

An place to keep cookies

=cut
my @cookie_jar		:Field
					:All('cookie_jar');

=item id_count

A running count of internal request IDs to use
B<id_count> will only accept NUMERIC type values.

=cut
my @id_count		:Field
					:All('id_count')
					:Type('NUMERIC' );
#
#=item requests
#
#A hash collection of requests that are in progress
#
#=cut
#my @requests		:Field
#					:All('requests');
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

	$args->{'name'} = 'tcli_http';

	$args->{'session'} = POE::Session->create(
      object_states => [
          $self => [qw(
          	_start
          	_stop
          	_shutdown
          	_default
          	_child

			establish_context
			get
			ProcessResponse
			ResponseProgress
			retry
			)],
      ],
	);

}

sub _init :Init {
	my $self = shift;

	$self->set(\@user_agents, [
		'TCLI Test Agent'
	]);

	$self->LoadYaml(<<'...');
---
Agent::TCLI::Parameter:
  name: user_agents
  help: An array of user_agents to be used, at random.
  manual: >
    Currently not supported. :(
  type: Param
---
Agent::TCLI::Parameter:
  name: url
  constraints:
    - HTTP_URL
  help: The full http url to send to the webserver
  manual: >
    This is the full http://www.example.com url that is to be sent to the
    server. Currently only http is supported. DNS will be resolved from the
    TCLI agent system.
  type: Param
---
Agent::TCLI::Parameter:
  name: id
  help: An id to tag the request with.
  manual: >
    This is sort of deprecated. It allows one to set an id to tag a request
    so that one can properly match up the response. With full RPC support
    this does not seem necessary any more, so if it seems useful let the
    author know.
  type: Param
---
Agent::TCLI::Parameter:
  name: response_code
  aliases: resp
  constraints:
    - UINT
  class: numeric
  help: The desired response code.
  manual: >
    Used with the tget command to specifiy the desired response code. tget
    will report ok if the proper code is received from the server.
  type: Param
---
Agent::TCLI::Parameter:
  name: retry_interval
  aliases: ri
  help: Retry in this many seconds
  constraints:
    - UINT
  class: numeric
  default: 30
  manual: >
    This parameter will cause a retry attempt of the same URL after the
    specified number of seconds. This will only happen upon
    successful completion of the first request. The same HTTP session
    is used for the retry.
    The default interval is 30 seconds.
  type: Param
---
Agent::TCLI::Parameter:
  name: retry_count
  aliases: rc
  constraints:
    - UINT
  class: numeric
  default: 1
  help: The number of times to retry when successful.
  manual: >
    This parameter will cause the specified number or retry attampts
    This will only happen upon successful completion of the
    first request. The default is 1.
  type: Param
---
Agent::TCLI::Command:
  name: http
  call_style: session
  command: tcli_http
  contexts:
    ROOT: http
  handler: establish_context
  help: http web cient environment
  manual: >
    Currently the http commands available only support limited capabilities.
    One can request a url and verify that a desired response code was
    received, but HTML content is not processed.
  topic: net
  usage: http tget url=http:\example.com\request resp=404
---
Agent::TCLI::Command:
  name: tget
  call_style: session
  command: tcli_http
  contexts:
    http: tget
  handler: get
  help: makes a requests and expects a specific response code
  manual: >
    Tget makes an http request for the supplied url and checks to see that the
    supplied response code is returned by the http server. This is useful in
    test scripts to ensure that a request has been responeded to properly.
  parameters:
    url:
    response_code:
    retry_interval:
    retry_count:
  required:
    url:
  topic: net
  usage: tget tget url=http:\example.com\request resp=404
---
Agent::TCLI::Command:
  call_style: session
  command: tcli_http
  contexts:
    http: cget
  handler: get
  help: makes a requests and returns response code
  manual: >
    Cget makes an http request for the supplied url and returns the
    response code that is returned by the http server. This is useful in
    checking what responses a server may be sending back.
  name: cget
  parameters:
    url:
    retry_interval:
    retry_count:
  required:
    url:
  topic: net
  usage: http cget url=http:\example.com\request
...

}

sub _start {
	my ($kernel,  $self,  $session) =
      @_[KERNEL, OBJECT,   SESSION];
	$self->Verbose("_start: tcli http starting");

	# are we up before OIO has finished initializing object?
	if (!defined( $self->name ))
	{
		$kernel->yield('_start');
		return;
	}

	# There is only one command object per TCLI
    $kernel->alias_set($self->name);

	# Keep the cm session so we can shut it down
	$self->set(\@poco_cm , POE::Component::Client::Keepalive->new(
  		max_per_host => 4, 		# defaults to 4
  		max_open     => 128, 	# defaults to 128
  		keep_alive   => 15, 	# defaults to 15
  		timeout      => 120, 	# defaults to 120
	));

	$self->set(\@poco_http , POE::Component::Client::HTTP->spawn(
		Agent     => $self->user_agents,
		Alias     => 'http-client',                  # defaults to 'weeble'
		ConnectionManager => $poco_cm[$$self],
#		From      => 'spiffster@perl.org',  # defaults to undef (no header)
#		CookieJar => $cookie_jar,
#		Protocol  => 'HTTP/1.1',            # defaults to 'HTTP/1.1'
#		Timeout   => 180,                    # defaults to 180 seconds
#		MaxSize   => 16384,                 # defaults to entire response
#		Streaming => 4096,                  # defaults to 0 (off)
#		FollowRedirects => 2                # defaults to 0 (off)
#		Proxy     => "http://localhost:80", # defaults to HTTP_PROXY env. variable
# 		NoProxy   => [ "localhost", "127.0.0.1" ], # defs to NO_PROXY env. variable
	));

	$self->Verbose(" Dump ".$self->dump(1),3 );

}

sub _stop {
    my ($kernel,  $self,) =
      @_[KERNEL, OBJECT,];
	$self->Verbose("_stop: ".$self->name." stopping",2);
	$poco_cm[$$self]->shutdown;
  	$self->set(\@poco_cm, undef);
}

sub get {
    my ($kernel,  $self, $session, $request, ) =
      @_[KERNEL, OBJECT,  SESSION,     ARG0, ];

	my $txt = '';
	my $param;
	my $command = $request->command->[0];
	my $cmd = $self->commands->{$command};

	return unless ( $param = $cmd->Validate($kernel, $request, $self) );

	$self->Verbose("get: url(".$param->{'url'}.") ");
	$self->Verbose("get: $command  params",3,$param);

	$param->{'try_count'} = 1;
	$param->{'completed'} = 0;
	$param->{'start_time'} = time();

	$self->requests->{$request->id}{'request'} = $request;
	$self->requests->{$request->id}{'param'} = $param;

	# execution
	$kernel->post( 'http-client' => 'request' => 'ProcessResponse' =>
		GET($param->{'url'},
			Connection => "Keep-Alive",
			),
		$request->id,		#tag
		'ResponseProgress', #progress callback
		'', 				#proxy override
 		);

	$request->Respond($kernel, 'Trying '.$param->{'url'},100)
		if ( $param->{'http_verbose'} );
	return;
}

sub ProcessResponse {
  my ($kernel,  $self, $request_packet, $response_packet) =
	@_[KERNEL, OBJECT,            ARG0,             ARG1 ];
	$self->Verbose("ProcessResponse: \tEntering ".$self->name." ",3 );

	my $http_request  = $request_packet->[0];
	my $http_response = $response_packet->[0];

	my $id		  = $request_packet->[1];
	my $request   = $self->requests->{$id}{'request'};
	my $param 	  = $self->requests->{$id}{'param'};

	my $txt;
	my $backtxt = '';

	$self->Verbose("ProcessResponse: for request id(".$id.")");
	$self->Verbose("ProcessResponse: request{".$id."}",3, $request );
	$self->Verbose("ProcessResponse: request{".$id."} param",2, $param );

	# Report only the rist response for the rtt.
	$param->{'end_time'} = time()  unless defined( $param->{'end_time'} );

#    my $response_string = $http_response->as_string();
#    $response_string =~ s/^/| /mg;

#  my $request_path = $http_request->uri->path . ''; # stringify

	if (!defined $http_response->code )
	{
		$self->Verbose("ProcessResponse: Bad HTTP response code id(".$id.") ",3);
		$request->Respond($kernel, "Error: ".$id." Bad HTTP response code",400);
		return;
	}

	#Push the response onto stack for later eval
#	push ( @{ $request->{'response_code'} },
#	  $http_response->code );

	# have we made all our requests?
	if (defined($param->{'retry_interval'} ) &&
		$param->{'retry_count'} > $param->{'try_count'}  )
	{
		$self->Verbose("ProcessResponse: id(".$id.") RETRY ri(".
			$param->{'retry_interval'}.") rc(".$param->{'retry_count'}.
			") tries(".$param->{'try_count'}.") ",2);
		$kernel->delay('retry' => $param->{'retry_interval'}, $id );

	}
	else  # we've exceeded retries with tries
	{
		$param->{'completed'} = 1;
		$self->Verbose("ProcessResponse: id(".$id.") COMPLETED ri(".
			$param->{'retry_interval'}.") rc(".$param->{'retry_count'}.
			") tries(".$param->{'try_count'}.") ",2);
	}

	# TODO break these out into separate handlers?
	$self->Verbose("ProcessResponse: id{".$id."} command(".$request->command->[0].") ");

	# Handle a respose to a tget request if done
	if ( $request->command->[0] eq 'tget' && $param->{'completed'} )
	{
		if ( $txt = $self->NotWithin( $http_response->code(),
			$param->{'response_code'}  )  )
		{
			$txt = "failed ".$id." - response within (".
			  $param->{'response_code'}.")".
			 # " for url ".$request->{'request'}.
			  "\n#\texpected in the range (".$param->{'response_code'}.")".
			  " got (".$http_response->code().")".
			  " for url ".$param->{'url'}."\n".$txt;
		}
		else
		{
			$txt = "ok ".$id." - response within (".
			  $param->{'response_code'}.")".

			 " ";
		}

		$self->Verbose("ProcessResponse: tget code txt(".$txt.$backtxt.") ",3);
		$request->Respond($kernel,  $txt.$backtxt );
		return;
	}
	# if not done, then do nothing and wait until we are.
	elsif ( $request->command->[0] eq 'tget' && not $param->{'completed'} )
	{
		$self->Verbose("ProcessResponse: tget tries(".$param->{'try_count'}.
			") rc(".$param->{'retry_count'}.") ",3);
		return;
	}
    # cget will report for every try.
	elsif ( $request->command->[0] eq 'cget' )
	{
		$txt = $param->{'url'}." ".
		"resp=".$http_response->code()." ";

		if ($param->{'retry_count'} > 1 )
		{
			$txt .= "try=".$param->{'try_count'}." ";
		}

		$self->Verbose("ProcessResponse: get txt(".$txt.$backtxt.") ",3);
		$request->Respond($kernel, $txt.$backtxt);
		return;
	}

	$self->Verbose("ProcessResponse: WHOOPS! id{".$id."}  ",1,$request);
}

sub retry {
  my ($kernel,  $self,  $id ) =
	@_[KERNEL, OBJECT, ARG0 ];

	my $txt;
	$self->Verbose("retry: id(".$id.") ");

	my $request   = $self->requests->{$id}{'request'};
	my $param 	  = $self->requests->{$id}{'param'};

	$param->{'try_count'}++ ;

		# execution
		$kernel->post( 'http-client' => 'request' => 'ProcessResponse' =>
			GET($param->{'url'},
				Connection => "Keep-Alive",
				),
			$id,
			'ResponseProgress', #progress callback
			'', #proxy override
  		);
}

sub ResponseProgress {
  my ($kernel,  $self, $gen_args, $call_args) =
	@_[KERNEL, OBJECT,      ARG0,       ARG1 ];
	$self->Verbose("ResponseProgress: \tEntering ".$self->name." " );

    my $req = $gen_args->[0];    # HTTP::Request object being serviced
    my $tag = $gen_args->[1];    # Request ID tag from.
    my $got = $call_args->[0];   # Number of bytes retrieved so far.
    my $tot = $call_args->[1];   # Total bytes to be retrieved.
    my $oct = $call_args->[2];   # Chunk of raw octets received this time.

    my $percent = $got / $tot * 100;

#    printf(
#      "-- %.0f%% [%d/%d]: %s\n", $percent, $got, $tot, $req->uri()
#    );

	my $request   = $self->requests->{$tag}{'request'};

#	Not doing anything yet.
}

=item show

This POE event handler executes the show commands.

=back

=cut

1;
#__END__

=head3 INHERITED METHODS

This module is an Object::InsideOut object that inherits from Agent::TCLI::Package::Base. It
inherits methods from both. Please refer to their documentation for more
details.

=head1 AUTHOR

Eric Hacker	 E<lt>hacker at cpan.orgE<gt>

=head1 BUGS

SHOULDS and MUSTS are currently not enforced.

Test scripts not thorough enough.

Probably many others.

=head1 LICENSE

Copyright (c) 2007, Alcatel Lucent, All rights resevred.

This package is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=cut