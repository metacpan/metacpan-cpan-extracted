package Agent::TCLI::Package::Net::Traceroute;
#
# $Id: Traceroute.pm 74 2007-06-08 00:42:53Z hacker $
#
=pod

=head1 NAME

Agent::TCLI::Package::Net::Traceroute

=head1 SYNOPSIS

From within a TCLI Agent session:

traceroute example.com

=head1 DESCRIPTION

This module provides a package of commands for the TCLI environment. Currently
one must use the TCLI environment (or browse the source) to see documentation
for the commands it supports within the TCLI Agent.

Makes a standard traceroute request.

=head1 INTERFACE

This module must be loaded into a Agent::TCLI::Control by an
Agent::TCLI::Transport in order for a user to interface with it.

=cut

use warnings;
use strict;

use Object::InsideOut qw(Agent::TCLI::Package::Base);

use POE qw/Component::Client::Traceroute/;
use NetAddr::IP;
use Getopt::Lucid qw(:all);
use Agent::TCLI::Command;
use Agent::TCLI::Parameter;


our $VERSION = '0.030.'.sprintf "%04d", (qw($Id: Traceroute.pm 74 2007-06-08 00:42:53Z hacker $))[2];

=head2 ATTRIBUTES

The following attributes are accessible through standard <attribute>
methods unless otherwise noted.

These attrbiutes are generally internal and are probably only useful to
someone trying to enhance the functionality of this Package module.

Some attributes may be created through the loading of the Parameters for this
command package. These are not documented separately. See the source for the
exact attribute names in use.

=over

=back

=head2 METHODS

Most of these methods are for internal use within the TCLI system and may
be of interest only to developers trying to enhance TCLI.

=over

=item new ( hash of attributes )

Usually the only attributes that are useful on creation are the
verbose and do_verbose attrbiutes that are inherited from Agent::TCLI::Base.

=cut

sub _start {
	my ($kernel,  $self,  $session) =
      @_[KERNEL, OBJECT,   SESSION];
	$self->Verbose("_start: tcli traceroute starting");

	# are we up before OIO has finished initializing object?
	if (!defined( $self->name ))
	{
		$kernel->yield('_start');
		return;
	}

	# There is only one command object per TCLI
    $kernel->alias_set($self->name);

	# Keep the pinger session so we can shut it down

	# Create a pinger component.
	POE::Component::Client::Traceroute->spawn(
    	Alias          => 'tracer',   # Defaults to tracer
    	FirstHop       => 1,          # Defaults to 1
    	MaxTTL         => 32,         # Defaults to 32 hops
    	Timeout        => 0,          # Defaults to never
    	QueryTimeout   => 3,          # Defaults to 3 seconds
    	Queries        => 3,          # Defaults to 3 queries per hop
    	BasePort       => 33434,      # Defaults to 33434
    	PacketLen      => 128,        # Defaults to 68
    	SourceAddress  => '0.0.0.0',  # Defaults to '0.0.0.0'
    	PerHopPostback => 0,          # Defaults to no PerHopPostback
    	Device         => undef,     # Defaults to undef
    	UseICMP        => 0,          # Defaults to 0
    	Debug          => 0,          # Defaults to 0
    	DebugSocket    => 0,          # Defaults to 0
	);

	return($self->name.":_start complete ");
} #end start

sub _shutdown {
    my ($kernel,  $self,) =
      @_[KERNEL, OBJECT,];
	$self->Verbose("_shutdown: ".$self->name." shutting down",2);
	$kernel->post('tracer' => 'shutdown');

	$kernel->alarm_remove_all();

	return($self->name.":_shutdown complete ");
}

=item trace

This POE event handler processes the trace command

=cut

sub trace {
    my ($kernel,  $self, $session, $request, ) =
      @_[KERNEL, OBJECT,  SESSION,     ARG0, ];

	my $txt = '';
	my $param;
	my $command = $request->command->[0];
	my $cmd = $self->commands->{'traceroute'};

	return unless ( $param = $cmd->Validate($kernel, $request, $self) );

	$self->Verbose("trace: param dump",4,$param);

	my $target;

	if ( defined( $param->{'target'} ) && ref( $param->{'target'} ) eq 'NetAddr::IP' )
	{
		$target = $param->{'target'}
	}
	else
	{
		$self->Verbose('trace: target not specified ');
		$request->Respond($kernel,  "Target must be defined in command line or in default settings.",412);
		return;
	}

	if ( $param->{'target'}->version() == 6 )
	{
		$request->Respond($kernel,  "IPv6 currently not supported.",400);
		return;
	}
	if ( $param->{'target'}->masklen() != 32 )
	{
		$request->Respond($kernel,  "Address blocks not supported.",400);
		return;
	}

	$self->Verbose("trace: target(".$param->{'target'}.") \n",2);

	# only one traceroute per host at a time
	if (defined($self->requests->{$param->{'target'}->addr}{'request'} ))
	{
		$self->Verbose('trace: trace in progress for target'.$param->{'target'}->addr);
		$request->Respond($kernel,"trace already in progress for ".$param->{'target'}->addr,409);
		return;
	}

	# $txt will be populated if there was an error.
	if ($txt)
	{
		$self->Verbose('trace: argument error '.$txt);
		$request->Respond($kernel, $txt,412);
		return;
	}

	my @trace_options;
	push(@trace_options,
		'MaxTTL'   		=> $param->{'max_ttl'},
		'FirstHop' 		=> $param->{'firsthop'},
    	'Timeout'  		=> $param->{'timeout'},
    	'QueryTimeout'  => $param->{'querytimeout'},
    	'Queries'		=> $param->{'queries'},
    	'BasePort'		=> $param->{'baseport'},
 		);
	push(@trace_options,'PerHopPostBack','TraceHopResponse')
		if $param->{'trace_verbose'};

	push(@trace_options,'UseICMP',1)
		if ($param->{'useicmp'} || ($^O eq "MSWin32"));

  	$self->requests->{$param->{'target'}->addr}{'request'} = $request;

	$self->Verbose(" target ".$param->{'target'}->addr." options ",
		1,\@trace_options );

	# execution
    $kernel->post(
        "tracer",           # Post request to 'tracer' component
        "traceroute",       # Ask it to traceroute to an address
        "TraceResponse",    # Post answers to 'trace_response'
        $param->{'target'}->addr, 	    # This is the host to traceroute to
        \@trace_options
#        [
#          PerHopPostback  => 'TraceHopResponse',
#          Queries   => 5,         # Override the global queries parameter
#          MaxTTL    => 30,        # Override the global MaxTTL parameter
#          Callback  => [ $args ], # Data to send back with postback event
#        ]
    );

	return($self->name.":trace done");
}

=item TraceResponse

This POE event handler processes the return data from the PoCo::Client::Traceroute.

=cut

sub TraceResponse {
	my ($kernel,  $self, $trace, $reply) =
	  @_[KERNEL, OBJECT,   ARG0,  ARG1];

    my ($destination, $options, $callback) = @$trace;
    my ($hops, $data, $error)              = @$reply;

	$self->Verbose("TraceResponse: destination(".$destination.")");
	my ($txt,$code);
	my $request = delete($self->requests->{$destination}{'request'});

	# define code first, so that error can include hops that might
	# have been successful.
	$code = 200;

	if ($error)
	{
		$txt = "trace failed for ".$destination.": ".$error;
		$code = 400;  # request_timeout
	}

	# Hops are returned whether success of failure.
	if ($hops)
	{
		$txt .= "Traceroute results for $destination\n";

		foreach my $hop (@$data)
		{
			my $hopnumber = $hop->{hop};
        	my $routerip  = $hop->{routerip};
        	my @rtts      = @{$hop->{results}};

        	$txt .= "$hopnumber\t$routerip";
        	foreach (@rtts)
        	{
          		if ($_ eq "*") { $txt .= "\t   *     "; }
          		else { $txt .= "\t".sprintf "%0.3fms ", $_*1000; }
        	}
        	$txt .= "\n";
		}
	}

	$request->Respond($kernel, $txt, $code );

	return($self->name.":TraceResponse done");
}

=item TraceHopResponse

This POE event handler processes the per hop return data from the
PoCo::Client::Traceroute.

=cut

sub TraceHopResponse {
	my ($kernel,  $self, $trace, $reply) =
	  @_[KERNEL, OBJECT,   ARG0,  ARG1];

    my ($destination, $options, $callback) = @$trace;
    my ($hops, $data, $error)              = @$reply;

	$self->Verbose("TraceResponse: destination(".$destination.")");
	my ($txt,$code);
	my $request = delete($self->requests->{$destination}{'request'});

	# define code first, so that error can include hops that might
	# have been successful.
	$code = 206;  # partial content

	if ($error)
	{
		$txt = "trace failed for ".$destination.": ".$error;
		$code = 400;  # request_timeout
	}

	# Hops are returned whether success of failure.
	if ($hops)
	{
		$txt .= "Traceroute results for $destination\n";

		foreach my $hop (@$data)
		{
			my $hopnumber = $hop->{hop};
        	my $routerip  = $hop->{routerip};
        	my @rtts      = @{$hop->{results}};

        	$txt .= "$hopnumber\t$routerip\t";
        	foreach (@rtts)
        	{
          		if ($_ eq "*") { $txt .= "* "; }
          		else { $txt .= sprintf "%0.3fms ", $_*1000; }
        	}
        	$txt .= "\n";
		}
	}

	$request->Respond($kernel, $txt, $code );

	return($self->name.":TraceResponse done");
}

sub _preinit :PreInit {
	my ($self,$args) = @_;

	$args->{'name'} = 'tcli_trace';

	$args->{'session'} = POE::Session->create(
      object_states => [
          $self => [qw(
          	_start
          	_stop
          	_shutdown
          	_default
          	_child
			establish_context
			trace
			TraceResponse
			TraceHopResponse
			settings
			show
			)],
      ],
	);
}

sub _init :Init {
	my $self = shift;

	$self->LoadYaml(<<'...');
---
Agent::TCLI::Parameter:
  name: firsthop
  constraints:
    - UINT
  default: 1
  help: Set the first hop.
  manual: >
    Firsthop sets the starting TTL value for the traceroute. firsthop
    defaults to 1 and can not be set higher than 255 or greater than max_ttl.
  type: Param
  class: numeric
---
Agent::TCLI::Parameter:
  name: max_ttl
  constraints:
    - UINT
  default: 30
  help: Set the maximum TTL.
  manual: >
    Maxttl sets the maximum TTL for the traceroute. Once this many hops
    have been attempted, if the target has still not been reached, the
    traceroute finishes and a 'MaxTTL exceeded without reaching target'
    error is returned along with all of the data collected. max_ttl
    defaults to 32 and can not be set higher than 255.
  type: Param
  class: numeric
---
Agent::TCLI::Parameter:
  name: timeout
  constraints:
    - UINT
  default: 0
  help: Set global timeout in seconds.
  manual: >
    Timeout sets the maximum time any given traceroute will run. After
    this time the traceroute will stop in the middle of where ever it
    is and a 'Traceroute session timeout' error is returned along with
    all of the data collected. Timeout defaults to 0, which disables
    it completely.
  type: Param
  class: numeric
---
Agent::TCLI::Parameter:
  name: querytimeout
  constraints:
    - UINT
  default: 3
  help: Set timeout for each query in seconds.
  manual: >
    Querytimeout sets the maximum before an individual query times out.
    If the query times out an * is set for the response time and the
    router IP address in the results data.
    QueryTtimeout defaults to 3 seconds.
  type: Param
  class: numeric
---
Agent::TCLI::Parameter:
  name: queries
  constraints:
    - UINT
  default: 3
  help: Set number of queries per hop.
  manual: >
    Queries sets the number of queries (packets) for each hop to send.
    The response time for each query is recorded in the results table.
    The higher this is, the better the chance of getting a response
    from a flaky device, but the longer a traceroute takes to run.
    Queries defaults to 3.
  type: Param
  class: numeric
---
Agent::TCLI::Parameter:
  name: baseport
  constraints:
    - UINT
    -
      - BETWEEN
      - 1
      - 65279
  default: 33434
  help: The starting port for udp traces.
  manual: >
    Baseport sets the first port used for traceroute when not using ICMP.
    The baseport is incremented by one for each hop, by traceroute
    convention. BasePort defaults to 33434 and can not be higher than 65279.
  type: Param
  class: numeric
---
Agent::TCLI::Parameter:
  name: useicmp
  constraints:
    - UINT
  help: Turns on icmp instead of udp.
  manual: >
    Useicmp causes the traceroute to use ICMP Echo Requests instead of UDP
    packets. This is advantagious in networks where ICMP Unreachables are
    disabled, as ICMP Echo Responses are usually still allowed.
  type: Param
  class: numeric
---
Agent::TCLI::Parameter:
  name: target
  constraints:
    - ASCII
  help: the target ip address
  manual: >
    The target IP address for the attack. The target may
    be specified as a domain name or as a dotted quad.
  type: Param
  class: NetAddr::IP
  show_method: addr
---
Agent::TCLI::Command:
  name: traceroute
  call_style: session
  command: tcli_trace
  contexts:
    ROOT: traceroute
  handler: trace
  help: determine route to a host
  manual: >
    Trace the route to a host either using UDP (the default) or ICMP query
    packets. This operates the same way the normal unix traceroute program
    works.
  parameters:
    target:
    firsthop:
    max_ttl:
    timeout:
    querytimeout:
    queries:
    baseport:
    useicmp:
  topic: network
  usage: traceroute target example.com
---
Agent::TCLI::Command:
  name: set
  call_style: session
  command: tcli_trace
  contexts:
    traceroute: set
  handler: settings
  help: set defaults for traceroutes
  parameters:
    target:
    firsthop:
    max_ttl:
    timeout:
    querytimeout:
    queries:
    baseport:
    useicmp:
  topic: network
  usage: traceroute set target=target.example.com
---
Agent::TCLI::Command:
  name: show
  call_style: session
  command: tcli_trace
  contexts:
    traceroute: show
  handler: show
  help: show current settings
  parameters:
    target:
    firsthop:
    max_ttl:
    timeout:
    querytimeout:
    queries:
    baseport:
    useicmp:
  topic: network
  usage: traceroute show timeout
...


}

1;
#__END__

=back

=head3 INHERITED METHODS

This module is an Object::InsideOut object that inherits from Agent::TCLI::Package::Base. It
inherits methods from both. Please refer to their documentation for more
details.

=head1 AUTHOR

Eric Hacker	 E<lt>hacker at cpan.orgE<gt>

=head1 BUGS

SHOULDS and MUSTS are currently not always enforced.

Test scripts not thorough enough.

Probably many others.

=head1 LICENSE

Copyright (c) 2007, Alcatel Lucent, All rights resevred.

This package is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=cut
