# $Id: XMPP.pm 62 2007-05-03 15:55:17Z hacker $
package Agent::TCLI::Transport::XMPP;

=pod

=head1 NAME

Net::CLI::Transport::XMPP - xmpp transport for Net::CLI

=head1 SYNOPSIS

todo

=head1 DESCRIPTION

=head1 GETTING STARTED

=cut

use warnings;
use strict;
use Carp;
use Date::Parse;

use POE;
use Net::Jabber;
use Socket;
use Agent::TCLI::Control;
use Agent::TCLI::Request;
require Agent::TCLI::Transport::Base;

use Object::InsideOut qw( Agent::TCLI::Transport::Base );
use Params::Validate qw(validate_with);

sub VERBOSE () { 0 }

our $VERSION = '0.031.'.sprintf "%04d", (qw($Id: XMPP.pm 62 2007-05-03 15:55:17Z hacker $))[2];

=head1 INTERFACE

=head2 ATTRIBUTES

The following attributes are accessible through standard accessor/mutator
methods and may be set as a parameter to new unless otherwise noted.

=over

=item jid

xmpp id of user we're connecting as'
B<set_jid> will only accept SCALAR type values.

=cut
my @jid 	   :Field('All' => 'jid', 'Type' => 'Net::XMPP::JID' );

=item jserver

B<jserver> will only accept SCALAR type values.

=cut
my @jserver 	   :Field('All' => 'jserver' );

=item jpassword

The password for the transport to use to log in to the server.
B<jpassword> will only accept scalar type values.

=cut
my @jpassword  :Field('All' => 'jpassword');

=item xmpp_debug

Sets the debug (verbosity) level for the XMPP libraries

=cut
my @xmpp_debug			:Field  :All('xmpp_debug');

=item xmpp_process_time

Sets the time in seconds to wait before calling XMPP Process to look for
more XMPP data. Defaults to 1 and shouldn't be much larger.

=cut
my @xmpp_process_time	:Field
						:Arg('name'=>'xmpp_process_time', 'default'=> 1 )
						:Acc('xmpp_process_time');

=item peers

An array of peers
B<set_peers> will only accept ARRAYREF type values.

=cut
#my @peers 	   :Field('All' => 'peers', 'Type' => 'ARRAY' );

# Holds the XMPP connection session
my @xmpp	 	   :Field('Get' => 'xmpp');

=item connection_retries

A max number to retry connection before giving up.
B<connection_retries> will only accept NUMERIC type values.

=cut
my @connection_retries
			:Field
			:Arg('name'=>'connection_retries','default'=>10)
			:Acc('connection_retries')
			:Type('NUMERIC' );

=item connection_delay

How long to wait beteen connection attempts when failed. Defaults to 30 seconds.
B<connection_delay> will only accept NUMERIC type values.

=cut
my @connection_delay
			:Field
			:Arg('name'=>'connection_delay','default'=>30)
			:Acc('connection_delay')
			:Type('NUMERIC' );

=item roster

Holds the Net::XMPP::Roster if enabled. To enable the roster,
a paramater of 'roster' => 1, must be passed in with new.
B<roster> will contain a Net::XMPP::Roster object after initialization if enabled.

=cut
my @roster			:Field
					:All('roster');

=item server_time

The time at the server. Useful for determining if messages were sent before we started up.
B<server_time> should only contain hash values.

=cut
my @server_time		:Field
#					:Type('hash')
					:All('server_time');

=item group_mode

The default setting to determine how to interact with groups. Options are:
'all' - process everything said in room
'named' - process only when called by name: (name followed by colon).
'log' -	don't listen to anything, but log events there (which ones?)
'prefixed' - named + anything beginning with a designated prefix character
B<group_mode> should only contain scalar values.

=cut
my @group_mode		:Field
#					:Type('scalar')
					:Arg('name'=>'group_mode', 'Default' => 'named' )
					:Acc('group_mode');

=item group_prefix

The group_prefix used for group moded prefixed.
B<group_prefix> should only contain a single scalar value.

=cut
my @group_prefix	:Field
#					:Type('scalar')
					:Arg('name'=>'group_prefix', 'Default' => ':' )
					:Acc('group_prefix');


# Standard class utils are inherited

#u_ subs can't be private if used in %init_args
#named u_ to sort nicer in Eclipse
sub u_is_text {
	return (
		 validate_pos( @_, { type => Params::Validate::SCALAR | Params::Validate::SCALARREF } )
		 )
}
sub u_is_num {
	return (
		 Scalar::Utils->looks_like_number($_[0])
		 )
}
sub u_is_int {
         my $arg = $_[0];
         return (Scalar::Util::looks_like_number($arg) &&
                 (int($arg) == $arg));
     }

sub _preinit :Preinit {
	my ($self, $args) = @_;

	$args->{'alias'} = 'transport_xmpp' unless defined( $args->{'alias'} );

	$args->{'session'} = POE::Session->create(
        object_states => [
        	$self => [ qw(
	            _start
            	_stop
        	    _shutdown
        	    _default
        	    _child

				ControlExecute
        	    Disconnected
        	    JoinPeerRooms
				JoinChatRoom
        	    Login
            	Online
            	Peers
        	    Process
        	    Set
        	    Show

	            recvmsg
	            recvmsgError
	            recvmsgGroupchat
	            recvmsgHeadline

				recv_pres

				recv_iqRequest
				recv_iqResponse

	            send_message
    	        send_presence

				PostRequest
				PostResponse

        	    SendChangeContext

				TransmitRequest
				TransmitResponse

        	)],
        ],
   );

}

sub _init :Init {
	my ($self, $args) = @_;
# Validate deep arguments
#    $self->Verbose("Validating arguments \n" ,1);
#	my %jabber_connection = validate ($args->{'jabber_connection'}, {
#        jabber_package	=> { regex => qr/^POE::Component::Jabber/,
#                            type => Params::Validate::SCALAR | Params::Validate::SCALARREF },
#		server			=> { type => Params::Validate::SCALAR | Params::Validate::SCALARREF },
#		port			=> { optional => 1, default => 5222,
#							callbacks =>
#							{ 'is a number' => sub {  Scalar::Utils->looks_like_a_number($_[0]) }
#							}},
#		password		=> 	{ type => Params::Validate::SCALAR | Params::Validate::SCALARREF },
#	});


}

=back

=head2 METHODS

=over

=item start

Get things rolling. Starts up a POE::Component::Jabber::Client using the user
provided config info.

=cut

sub _start {
	my ($kernel,  $self, $session) =
	  @_[KERNEL, OBJECT,  SESSION];

	# are we up before OIO has finished initializing object?
	if (!defined( $self->alias ))
	{
		$kernel->yield('_start');
		return;
	}

	$self->Verbose("_start: ".$self->alias." Starting up");

	# OK, now we can start up POE stuff.
	$kernel->alias_set($self->alias);

	my $xmpp = Net::Jabber::Client->new(
  		'debuglevel'	=> $xmpp_debug[$$self],
		'debugfile'		=> 'stdout',
	);

  	# Add a namespace for IQ nodes to embed YAML output
	$xmpp->AddNamespace(
			ns    => "tcli:request",
            tag   => "tcli",
            xpath => {
            	'Version'	=> { 'path' => 'version/text()' },
             	'Yaml'		=> { 'path' => 'yaml/text()' },
             	'Request'	=> { 'type' => 'master'},
            }
	);

#	$self->Verbose("_start: Setting General XMPP Callbacks" , 2 );

#	$xmpp->SetCallBacks(
#		'send'			=> $session->postback('VerboseCallBack'),
#		'receive'		=> $session->postback('VerboseCallBack'),
#		'presence'		=> $session->postback('recv_presence'),
#		'iq'			=> $session->postback('recv_iq'),
#	);

	$self->Verbose("_start: Setting XMPP Message Callbacks" , 2 );

	$xmpp->SetMessageCallBacks(
    	'normal'		=> $session->postback('recvmsg'),
	    'chat'			=> $session->postback('recvmsg'),
    	'groupchat'		=> $session->postback('recvmsgGroupchat'),
    	'headline'		=> $session->postback('recvmsgHeadline'),
    	'error'			=> $session->postback('recvmsgError'),
	);

#	$xmpp->SetPresenceCallBacks(
#    	available	=> $session->postback('recv_pres'),
#		unavailable	=> $session->postback('recv_pres'),
#	);

    $xmpp->SetIQCallBacks(
		'tcli:request'	=> {
			'get'	=>	$session->postback('recv_iqRequest'),
		#	'set'	=>	function,
			'result'=>	$session->postback('recv_iqResponse'),
			},
	);

	$self->set(\@xmpp, $xmpp);

	$kernel->yield('Login') if (defined( $self->jpassword ));

	return ($self->alias."_start whohoo");
} # End sub start

=item stop

Mostly just a placeholder.

=cut

sub _stop {
  my ($kernel,  $self, $session) =
    @_[KERNEL, OBJECT,  SESSION];
    $self->Verbose("\n ".$self->alias." stopping \n\n" ,1);
	return ($self->alias."_stop whohoo");
}

=item shutdown

Forcibly shutdown

=cut

sub _shutdown :Cumulative {
    my ($kernel,  $self, $session) =
    @_[KERNEL, OBJECT,  SESSION];
	# TODO, do some proper signal handling
	# especially reconnect on HUP and something on INT
	$self->Verbose('Shutdown');

	# This is to keep from reconnectiing when XMPP responds that it is disconnected.
	$self->connection_retries(0);

	if ( defined($self->control_options)
		&& exists( $self->control_options->{'packages'}  ))
	{
		# Shut down any packages.
		foreach my $package ( @{$self->control_options->{'packages'} })
		{
			$kernel->post( $package->name => '_shutdown'  );
		}

	}

	if ( $xmpp[$$self]->Connected )
	{
		$xmpp[$$self]->Disconnect;
		$self->Verbose("_shutdown: Disconnecting ");
	}
	# define xmpp
	# what about Disconnected????

	$self->xmpp->SetMessageCallBacks(
    	'normal'		=> undef,
	    'chat'			=> undef,
    	'groupchat'		=> undef,
    	'headline'		=> undef,
    	'error'			=> undef,
	);

	$self->xmpp->SetPresenceCallBacks(
    	available	=> undef,
		unavailable	=> undef,
	);

    $self->xmpp->SetIQCallBacks(
		'tcli:request'	=> {
			'get'	=>	undef,
			'set'	=>	undef,
			'result'=>	undef,
			},
	);


#    $_[KERNEL]->alias_remove( $_[OBJECT]->get_alias );

}

sub Disconnected {
	my ($kernel,  $self, $count ) =
	  @_[KERNEL, OBJECT,   ARG0 ];

	# if connection retries is zero, then we shutdown with no delay.
	# This is important when we try to shutdown and the
	# xmpp->Disconnect is called. :)
	if ( !defined( $count )  && $connection_retries[$$self] > 0 )
	{
		$kernel->delay_set('Disconnected', $connection_delay[$$self], 1 );
		$self->Verbose("Disconnected: got XMPP disconnect waiting ".$connection_delay[$$self]." seconds" );
		return;
	}
	else
	{
		$count++;
		$self->Verbose("Disconnected: count ($count) \n" );
	}

	if ( $count >= $connection_retries[$$self] )
	{
  		$kernel->yield('_shutdown');
		$self->Verbose("Disconnected: SHUTDOWN in progress");
		return;
	}

	# make connection
	$self->Verbose("Disconnected: XMPP connecting to ".$jserver[$$self] );
	$xmpp[$$self]->Connect(
		hostname	=> $jserver[$$self],
	);
	if ( $xmpp[$$self]->Connected )
	{
		$kernel->yield('Login');
		$self->Verbose("Disconnected: Got connected ");
		return;
	}

	$kernel->delay_set('Disconnected', $connection_delay[$$self], $count );

} #end sub Disconnected

=item JoinPeerRooms

This POE event handler will go through each of the users in the peers array,
and if the peers is a groupchat, join the conference room. It will check to
make sure it is not already conencted (though this could be buggy). It does
not take any arguments.

=cut

sub JoinPeerRooms {
	my ($kernel,  $self, ) =
	  @_[KERNEL, OBJECT, ];
    $self->Verbose("JoinPeerRooms:  ",2);

	foreach my $user ( @{$self->peers} )
	{
		if ( $user->protocol =~ /groupchat/  )
		{
			if ( defined( $self->controls ) &&
				exists( $self->controls->{ $user->id.'-groupchat' } ) )
			{
				# should already be logged on?
			    $self->Verbose("JoinPeerRooms: already connected to ".$user->id ,2);
				return;
			}
			$kernel->yield('JoinChatRoom',
				$user->get_name,		# room name
				$user->get_domain,		# server
				$user->password,		# secret
			)
		}
	}
}

sub JoinChatRoom {
	my ($kernel,  $self, $room, $server, $secret) =
	  @_[KERNEL, OBJECT,  ARG0,    ARG1,   	ARG2];
    $self->Verbose("JoinChatroom: $room at $server ",2);

    $self->xmpp->MUCJoin(
    	'room'		=> $room,
		'server'	=> $server,
		'nick'		=> $self->jid->GetUserID,
		'password'	=> defined($secret) ? $secret : undef,
	);
}

sub Login {
	my ($kernel,  $self, ) =
	  @_[KERNEL, OBJECT, ];

	my $txt = '';

	# make connection
	$self->Verbose("login: XMPP connecting to ".$jserver[$$self] );
	$xmpp[$$self]->Connect(
		hostname	=> $jserver[$$self],
	);

	my @login;
	if ( $xmpp[$$self]->Connected()  )
	{
		#log in
		$self->Verbose("login: XMPP trying login as ".$self->jid()->GetUserID );
		@login = $xmpp[$$self]->AuthSend(
			username	=> $self->jid()->GetUserID,
			password	=> $jpassword[$$self],
			resource	=> $self->jid()->GetResource,
		);
		$self->Verbose("login: Did login for ".$self->jid()->GetUserID." Got ".$login[0] );

		if ( defined($login[0]) && $login[0] eq 'ok')
		{
		    $kernel->yield('Online');
		}
		elsif ( defined($login[1]) )
		{
			$txt .= "Login error-> ".$login[1];
		}
		else
		{
			$txt .= "Bad Login error-> ".$xmpp[$$self]->GetErrorCode();
		}
	}
	else
	{
		$txt .= "Connection error-> ".$xmpp[$$self]->GetErrorCode();
	}

	if ($txt ne '' )
	{
		$self->Verbose("login: ".$txt."\n",1,$xmpp[$$self]->GetErrorCode());
		$kernel->delay_set('Disconnected' => 10 , 1 );
	}

} # end sub login

sub Online {
	my ($kernel,  $self,  ) =
	  @_[KERNEL, OBJECT,  ];
	$self->Verbose("Online: \n" ,1);

	my %server_time = $self->xmpp->TimeQuery('mode'=>'block');
	$self->Verbose("Online: server_time($server_time{display})", 1,\%server_time );
	$self->set(\@server_time, $server_time{utc});

	# start roster
	if ($self->roster)
	{
		$self->Verbose("Online: enabling Roster ");
		$self->set(\@roster, $self->xmpp->Roster);
	}

	if (defined($self->control_options) )
	{
		$self->control_options->{'local_address'} = $self->Address
			unless defined($self->control_options->{'local_address'});
	}

	$kernel->delay_set( 'Process' => $xmpp_process_time[$$self] );

    $kernel->yield('send_presence',(
    {
		status   =>  'Online',
		priority =>  '1',
    } ) );

	$kernel->yield('JoinPeerRooms') if defined($self->peers);

} #end sub Online

=item Process (    )

This event interfaces with the XMPP Process to have it check for new data

=cut

sub Process {
	my ($kernel,  $self, ) =
	  @_[KERNEL, OBJECT, ];
	$self->Verbose("Process: " , 4);
	my $result = $xmpp[$$self]->Process(1);
	if ( defined($result) )
	{
		$self->Verbose("Process: (".$result.") for ".$self->alias." as ".$jid[$$self]->GetJID('full') );
		$kernel->delay_set( 'Process' => $xmpp_process_time[$$self] );
    }
    else
    {
		$kernel->yield( 'Disconnected' );
    }
} # End Process

# When we recv anything from XMPP the $response will be
# an array of the XMPP Session ID and then the XML message
# In ARG1 for some reason...

sub recv_pres {
	my ($kernel,  $self, $jSessionID, $response) =
      @_[KERNEL, OBJECT,        ARG0,      ARG1 ];
    my $msg = $response->[1];
    $self->Verbose( "\tRP\tGot no response \n") if ( !defined ($response) );

#    my $thread = $self->get_thread($msg);
#    $self->Verbose( "\tRP\tThread:  ".$thread->id()." \n") if ( defined ($thread));

	# If we get our own presence, ignore it.
    my $from = $msg->GetFrom('jid');
    return if ( $from eq $self->jid->GetUserID );

    # TODO more presence handling
	# need to put presence into thread participant state? Maybe but we
	# don't get the thread with the presence.
	# how would we find group participants in a groupchat?
	# do we need have presence of groupchat participants for anything
    return ();
}

sub GetRequestForNode {
	my ($self, $node ) = @_;
	# This is used to package up a simple request easily

	my $input = $node->GetBody;
	$self->Verbose("GetRequestForNode: input($input)\n",2);

	my $request = Agent::TCLI::Request->new({
					'sender'	=> $self->alias,
					'postback'	=> 'PostResponse',
					'input'		=> $input,

					'response_verbose' => 1,

					'verbose'		=> $self->verbose,
					'do_verbose'	=> $self->do_verbose,
	});

	$request->set_recv($node);

	return( $request );
}

sub recvmsg {
 my ($kernel,  $self, $jSessionID, $response) =
	  @_[KERNEL, OBJECT,        ARG0,      ARG1 ];
	my $msg = $response->[1];
	$self->Verbose("recvmsg: got message from ".
  	$msg->GetFrom('jid')->GetJID('full')." ",1);

	my $control = $self->GetControlForNode( $msg );

	return unless $control;

	my $request = $self->GetRequestForNode($msg);

	# The control is transport agnostic. All it needs to know
	# is the input and what is stored in the control and request.
	$self->Verbose("recvmsg: sending to contol \n",2);

	$kernel->post( $control->id() => 'Execute' => $request );
}

sub recvmsgGroupchat {
	my ($kernel,  $self, $jSessionID, $packet) =
	@_[KERNEL, OBJECT,        ARG0,      ARG1 ];
	my $msg = $packet->[1];
	$self->Verbose("recvmsgGroupchat: msg dump",3,$msg);

	if ( $msg->GetFrom eq $jid[$$self] )
	{
		$self->Verbose("recvmsgGroupchat: ignoring from me \n",2);
		return;
	}

	if ($msg->DefinedX('jabber:x:delay') )
	{
		$self->Verbose("recvmsgGroupchat: delayed message, ignoring \n",2);
		return;
	}

#	# The server will hold older messages. We need to ignore these.
#	# Giving a 10 second window for past.
#	my $msgtime = str2time( $msg->GetTimeStamp );
#	$self->Verbose("recvmsgGroupchat: ts (".$msg->GetTimeStamp.") msgtime (".$msgtime.") time(".time().")  ");
#	if ( $msgtime < time - 10 )
#	{
#		$self->Verbose("recvmsgGroupchat: ignoring past messages \n");
#		return;
#	}

	my $control = $self->GetControlForNode( $msg );
	return unless $control;

	my $input = $msg->GetBody;
	$self->Verbose("recvmsgGroupchat: got input($input)\n",4);

	# currently, this is what we're joining the chatroom as.
	my $me = $jid[$$self]->GetUserID;

	# Figure out if we're addressed in this input depends on mode.
	my $doit = 0;
	if ( $group_mode[$$self] eq 'log' )
	{
		$self->Verbose("recvmsgGroupchat:log ignoring ");
		return;
	}
	elsif ( $group_mode[$$self] eq 'all' )
	{
		$self->Verbose("recvmsgGroupchat:all input($input) ");
	}
	elsif ( $group_mode[$$self] =~ /named|prefixed/ )
	{
		if ( $input =~ /$me:/i  )
		{
			my ($ignore, $myinput) = split(/$me:/, $input, 2);
			#put input without our name into body.
			$msg->SetBody($myinput);
			$self->Verbose("recvmsgGroupchat:named input($input) ");
		}
		elsif ( $input =~ /$group_prefix[$$self]/i &&
			$group_mode[$$self] eq 'prefixed' )
		{
			my ($ignore, $myinput) = split(/$group_prefix[$$self]/, $input, 2);
			#put input without prefix into body.
			$msg->SetBody($myinput);
			$self->Verbose("recvmsgGroupchat:prefixed input($input) ");
		}
		else
		{
			$self->Verbose("recvmsgGroupchat:named-prefixed not for me ignoring");
			return;
		}
	}
	else
	{
		$self->Verbose("recvmsgGroupchat: mode error ignoring");
		return;
	}

#	if ( $input =~ /$me:/i )
#	{
#		$input =~ s/\s*($me):\s*//;
#		my $target = $1;
#		$self->Verbose("recvmsgGroupchat  input($input) target($target) ");
#		if ( $target ne $me )
#		{
#			$kernel->yield('send_message'
#				 =>  $msg
#				 =>  "I heard my name but saw no command. Use '$me: help' to get help."
#			);
#			return;
#		}
#		else
#		{
#			#put input without our name into body.
#			$msg->SetBody($input)
#		}
#	}
#	else
#	{
#		$self->Verbose("but it's to the group and not for $me \n");
#		return;
#	}

	my $request = $self->GetRequestForNode($msg);

	$self->Verbose("recvmsgGroupChat: sending to contol \n",2);

	$kernel->post( $control->id() => 'Execute' => $request );
}

sub recvmsgHeadline {
	my ($kernel,  $self, $jSessionID, $response) =
	  @_[KERNEL, OBJECT,        ARG0,      ARG1 ];
	my $msg = $response->[1];
	return unless $self->authorized(
	  	$msg->GetFrom('jid'),
	  	);
	my $input = $msg->GetBody;
	$self->Verbose("recvmsgHeadline: got headline ($input) \n");
	warn ("recvmsgHeadline: got headline ($input) \n");
	return
}

sub recvmsgError {
  my ($kernel,  $self, $jSessionID, $packet) =
    @_[KERNEL, OBJECT,        ARG0,    ARG1 ];
	my $msg = $packet->[1];
	$self->Verbose("recvmsgError jSessionID",1);

	$self->Verbose("recvmsgError packet");

	return unless $self->authorized
	(
  		$msg->GetFrom('jid'),
  	);
	my $input = $msg->GetBody;
	$self->Verbose("recvmsgError got input($input)\n",3);
#  warn ("recvmsgError got command '$input'\n");
	return
}

sub recv_iqRequest {
	my ($kernel,  $self, $jSessionID, $packet) =
	  @_[KERNEL, OBJECT,        ARG0,   ARG1 ];
	my $msg = $packet->[1];
	$self->Verbose("recv_iqRequest: got message from ".
		$msg->GetFrom('jid')->GetJID('full')." ");

	# Since we're here. this is a get IQ, and thus the 'request'
	# better be a "tcli:request"

	# TODO Assuming version is 1.0 for now.
#	my $query = $msg->GetQuery;

	my $packed_request = $msg->GetQuery->GetYaml;

#	$self->Verbose("recv_iqRequest: msg",4,$msg);
#	$self->Verbose("recv_iqRequest: GetRequest",3,$msg->GetQuery->GetRequest);

	# Unpack the request..
	my $request = $self->UnpackRequest($packed_request);

	# Need to put us on the bottom of the stack so we can return response
	$request->unshift_sender($self->alias);
	$request->unshift_postback('PostResponse');

	my $control = $self->GetControlForNode( $msg );

	return unless $control;

	$self->Verbose("recv_iqRequest: sending to contol(".$control->id().") \n",1);
	$self->Verbose("recv_iqRequest: control dump.... \n".$control->dump(1), 5 );

	# Sometimes, control has not started, so we wiat if we have to.
	if ( defined($control->start_time) )
	{
		$kernel->post( $control->id() => 'Execute' => $request );
	}
	else
	{
		$kernel->delay('ControlExecute' => 1 => $control, $request );
	}
}

sub recv_iqResponse {
	my ($kernel,  $self, $jSessionID, $packet) =
	  @_[KERNEL, OBJECT,        ARG0,   ARG1 ];
	my $msg = $packet->[1];
	$self->Verbose("recv_iqResponse: got message from ".
		$msg->GetFrom('jid')->GetJID('full')." ");

	# Since we're here. this is a result IQ, and thus the 'request' is really
	# a response and is a "tcli:request" result

	# TODO Assuming version is 1.0 for now.
	my $packed_response = $msg->GetQuery->GetYaml;

#	$self->Verbose("recv_iqResponse: msg",1,$msg); #->GetRequest
#	$self->Verbose("recv_iqResponse: XMLNS",1,$msg->GetQueryXMLNS);
#	$self->Verbose("recv_iqResponse: GetQuery",1,$msg->GetQuery);
#	$self->Verbose("recv_iqResponse: GetYaml",1,$msg->GetQuery->GetYaml);
#	$self->Verbose("recv_iqResponse: GetRequest",1,\$msg->GetQuery->GetRequest);

	# Unpack the response..
	my $response = $self->UnpackResponse($packed_response);

	# The bottom of the stack should be where to go.
	my $sender = $response->shift_sender;
	my $postback = $response->shift_postback;

	$self->Verbose("recv_iqResponse: posting to ".
		$sender." => ".$postback." => ".$response->id);
	$kernel->call( $sender => $postback => $response );
}

sub PostRequest {
	my ($kernel,  $self, $sender, $request, ) =
  	  @_[KERNEL, OBJECT,  SENDER,      ARG0, ];
	$self->Verbose("PostRequest: sender(".$sender->ID.")
		request(".$request->id.") \n");

	my $addressee;

	# First, check if we're on the bottom of the stack.
	if ( $request->sender->[0] eq $self->alias )
	{
		#we're here, take us off
		$request->shift_sender;
		$request->shift_postback;
	}
#	elsif ( defined($request->sender->[0]) )  # implied != $self->alias
#	{
#		# TODO Genereate real error
#		$self->Verbose("PostRequest: Whoops! Got something in sender0 that shouldn't be there \n ".$request->dump(1));
#		return;
#	}

	if ( $request->sender->[0] eq 'XMPP' )
	{
		#take off XMPP and adressee.
		$request->shift_sender;
		$addressee = $request->shift_postback;
	}
	elsif ( defined($request->sender->[0]) )  # implied != 'XMPP'
	{
		# TODO Genereate real error
		$self->Verbose("PostRequest: Whoops! Got something in sender0 that shouldn't be there \n ".$request->dump(1));
		return;
	}

	# make sure sender put themselves on stack.
	# need to resolve POE sender to alias to do this.
#	if ( !defined($request->sender->[0]) || $request->sender->[0] ne $sender )
#	{
#		# Do them a favor and put them on.
#		$request->unshift_sender( $sender );
#		# but we'll have to assume they are at least compliant with response returns.
#		$request->unshift_postback('PostResponse');
#		$self->Verbose($self->alias.":PostRequest: putting ".$sender." on sender/postback stack");
#	}
	# Transmit will take care of putting self onto stack.

	# Now Transmit it
	$kernel->call($self->alias, 'TransmitRequest', $request, $addressee );
	return;
}

sub PostResponse {
	my ($kernel,  $self, $sender, $response, $control) =
  	  @_[KERNEL, OBJECT,  SENDER,      ARG0,     ARG1];
	$self->Verbose("PostResponse: sender(".$sender->ID.")
		Code(".$response->code.") \n");

#	my $request = $response->request;

	# The response should come back with either message nodes attached
	# or something in the sender/postback stack to provide
	# directions on where to go. If there a XMPP in the sender/postback
	# that means the request should get transmitted as a whole request (iq),
	# and not as a message/body, so let Transmit handle that.

	# First, check if we're on the bottom of the stack.
	if ( defined($response->sender->[0]) && $response->sender->[0] eq $self->alias )
	{
		#we're here, but we don't take us off anymore, so there is not much to do.
	}
	elsif ( defined($response->sender->[0]) )  # implied != $self->alias
	{
		# TODO Genereate real error
		$self->Verbose("PostResponse: Whoops! Got something in sender0 that shouldn't be there \n ".$response->dump(1));
		return;
	}

	# Now if there's anything for XMPP on the stack, Transmit it
	if ( defined($response->sender->[1]) && $response->sender->[1] eq 'XMPP' )
	{
		#we're here, take us off bottom
		$response->shift_sender;
		$response->shift_postback;
		$kernel->yield('TransmitResponse', $response );
		return;
	}
	elsif ( defined($response->sender->[1]) )  # implied != 'XMPP'
	{
		# TODO Genereate real error
		$self->Verbose("PostResponse: Whoops! Got something in sender1 that shouldn't be there \n ".$response->dump(1));
		return;
	}

	my $msg = $response->get_send();

	# If the send message has not been set up, then do it.
	if ( ref($msg) ne 'Net::XMPP::Message')
	{
  		$self->Verbose("PostResponse:  Creating new Send XMPP::Message", 2);

		# If we've got a recieved message, use it
		if ( ref( $response->get_recv ) =~ /Message/)
		{
			if ( $response->get_recv->GetType eq 'groupchat' )
			{
  				$msg = $response->get_recv()->Reply();
				$self->Verbose("PostResponse: Reply dump ", 5, $msg);
  				$msg->SetTo( $response->get_recv->GetFrom('jid')->GetJID('base') );
				$self->Verbose("PostResponse: Getfrom base ".$response->get_recv->GetFrom('jid')->GetJID('base'), 2 );
				$msg->SetFrom( $jid[$$self] );
			}
			else
			{
  				$msg = $response->get_recv()->Reply();
			}
		}
		elsif ( defined($control) )
		{
	  		$msg = Net::XMPP::Message->new();
  			$msg->SetTo( $control->get_jid() );
			$msg->SetFrom ( $jid[$$self] );
		}
		else
		{
			$self->Verbose("PostResponse: Can't post, nowhere to go");
			return;
		}
	}

	$msg->SetBody( $response->body );

	$self->Verbose("PostResponse: Sending to xmpp", 2);
	$self->Verbose("PostResponse: msg dump ", 5, $msg);

	# Put $msg in request for next time.
	$response->set_send($msg);

	$self->xmpp->Send($msg);
}

sub TransmitRequest {
	my ($kernel,  $self, $sender, $request, $addressee ) =
  	  @_[KERNEL, OBJECT,  SENDER,     ARG0,       ARG1 ];
	$self->Verbose($self->alias.":TransmitRequest: id(".
		$request->id.") \n");

	# Put us on bottom so we get the response back
	$request->unshift_sender('XMPP');
	$request->unshift_postback($self->jid->GetJID('full') );

	# Prepare the request..
	my $packed_request = $self->PackRequest($request);

	# Create new msg
	my $msg = Net::XMPP::IQ->new();

	# addressee must have resource, default to /tcli if not provided
	$addressee .= '/tcli' unless ($addressee =~ qr(/) );

	$msg->SetIQ (
		'to'	=> $addressee,
		'from'	=> $self->jid,
		'type'	=> 'get',
	);

	my $msgRequest = $msg->NewChild("tcli:request");

	$msgRequest->SetRequest(
		'Version'	=> '1.0',
		'Yaml'		=>	$packed_request,
	);

	$self->Verbose($self->alias.":TransmitRequest: Sending to xmpp for $addressee", 1);

	$self->xmpp->Send($msg);

}

sub TransmitResponse {
	my ($kernel,  $self, $sender, $response, ) =
  	  @_[KERNEL, OBJECT,  SENDER,      ARG0, ];
	$self->Verbose("TransmitResponse: Code(".$response->code.") id(".
		$response->id.") \n");

#	my $request = $response->request;
	my $addressee;

	# First, check if we're on the bottom of the stack.
	if ( $response->sender->[0] eq 'XMPP' )
	{
		#we're here, take us off
		$response->shift_sender;
		$addressee = $response->shift_postback;
	}
	elsif ( defined($response->sender->[0]) )  # implied != 'XMPP'
	{
		# TODO Genereate real error
		$self->Verbose("TransmitResponse: Whoops! Got something in sender that shouldn't be there ".$response->dump(1));
		return;
	}
	else
	{
		# TODO Genereate real error
		$self->Verbose("TransmitResponse: Got nowhere to go. ");
		return;
	}

	# Prepare the response..
	my $packed_response = $self->PackResponse($response);

	# Create new msg
	my $msg = Net::XMPP::IQ->new();

	# addressee must have resource. For now, everybody should be tcli.
	$msg->SetIQ (
		'to'	=> $addressee,
		'from'	=> $self->jid,
		'type'	=> 'result',
	);

	my $msgRequest = $msg->NewChild("tcli:request");

	$msgRequest->SetRequest(
		'Version'	=> '1.0',
		'Yaml'		=>	$packed_response,
	);

	$self->Verbose("TransmitResponse: Sending to xmpp for $addressee", 1);

	$self->xmpp->Send($msg);

}

sub SendChangeContext {
	my ($kernel,  $self, $control ) =
	  @_[KERNEL, OBJECT,    ARG0 ];
	# for xmpp, we announce context with presence.
	# for a terminal, it might be a prompt...
	$self->Verbose("SendChangeContext: for control ".$control->id());

	# Todo, what happens with a groupchat?

	my $presence = Net::XMPP::Presence->new(
		'to'		=> $control->get_jid(),
		'status'	=> 'Available',
		'priority'	=> '1',
		'type'		=> $control->print_context,
	);

	$self->Verbose("SendChangeContext: presence dump",4,$presence);

	$xmpp[$$self]->PresenceSend($presence);
}

sub recv_exit {
	my ($kernel,  $self,  ) =
	  @_[KERNEL, OBJECT,  ];

	$self->Verbose("recv_exit: got XMPP exit \n" );

	$kernel->delay_set('Disconnected',30, 1 );
} #end sub recv_exit

=item send_presence

Sends a xmpp presence message. See Net::XMPP::Presence for parameter details.

=begin code

    $kernel->yield('send_presence' => {
    	'type'		=> 'available',   # optional, defaults
       	'to'		=>  xmpp_id,    # optional, no default
        'status'	=>  'Online',     # optional, defaults
        'priority'	=>  '8',          # optional, defaults
        });

=end code

=cut

sub send_presence {
  my ($kernel,  $self, $args) =
    @_[KERNEL, OBJECT,  ARG0];
  my $xmpp = $xmpp[$$self];

  # get params or use defaults
  my $status   = defined($args->{'status'})   ? $args->{'status'}   : 'Online';
  my $priority = defined($args->{'priority'}) ? $args->{'priority'} : '8';
  my $to       = defined($args->{'to'})       ? $args->{'to'}       : undef;
  my $type     = defined($args->{'type'})     ? $args->{'type'}     : 'available';

  $self->Verbose( "send_presence: type($type) status($status) priority($priority) \n");

#	  SetPresence(to=>string|JID
#              from=>string|JID,
#              type=>string,
#              status=>string,
#              priority=>integer,
#              meta=>string,
#              icon=>string,
#              show=>string,
#              loc=>string)

  $xmpp[$$self]->PresenceSend(
  	'to'		=> $to,
	'status'	=> $status,
	'priority'	=> $priority,
	'type'		=> $type,
  );
  return;
}  # end end_pres

=item send_message

Sends a xmpp message for a control. Takes the thread and the messaage as parameters. It will overwrite the control->send attribute text with the message parameter.

=begin code

   $kernel->yield('send_message' => $control => $message )

=end code

=cut

sub send_message {
	my ($kernel,  $self, $msg, $message) =
	  @_[KERNEL, OBJECT,  ARG0,     ARG1];
	return unless (my $xmpp = $self->xmpp);
	$self->Verbose("send_message: node(".$msg->GetFrom.") Message(".$message.") \n");
	my $rmsg;
	# If the send message has not been set up, then do it.
	if ( ref($msg) eq 'Net::XMPP::Message')
	{
	  	$self->Verbose("send_message:  Creating new reply XMPP::Message", 2);

	  	# If we've got a recieved message, use it
	  	$rmsg = $msg->Reply();
		if ( $msg->GetType eq 'groupchat' )
		{
  			$self->Verbose("send_response: Reply dump ", 2, $rmsg);
  			$rmsg->SetTo( $msg->GetFrom('jid')->GetJID('base') );
			$rmsg->SetFrom( $jid[$$self] );
  			$self->Verbose("send_response: Reply post dump ", 2, $rmsg);
		}
	}

	$msg->SetBody( $message );

	$self->Verbose("send_message: Sending to xmpp", 2);
#	$control->send($rmsg);
	$self->xmpp->Send($rmsg);

} # end sub xmpp_send_msg

=item GetControlForNode (  node  )

Determines the control from a node and returns the control object.

Takes a node parameter and returns the hash key to the proper control
object in the controls array. If the control object is not in the array,
it will add it.

When a new control object is created, a new Control session must be started
for the control and that is handled here as well.

=cut

sub GetControlForNode {
	my ($self, $node) = @_;
	$self->Verbose("GetControlForNode: node(".ref($node).") \n");

	my $type = $node->GetType;
	my $user = $node->GetFrom('jid');

	# chats to other groupchat users come from group/nick and not from user.
	# don't want peer chats from group.....
	my $user_protocol = $type eq 'groupchat' ? qr(xmpp_groupchat) : qr(xmpp);

	# Don't talk to oneself.......
	return if ( $user->GetJID('full') eq $self->jid->GetJID('full') );

	# or to self in chatroom
	return if ( $user->GetResource eq $self->jid->GetUserID );

	$self->Verbose("GetControlForNode: type(".$type.") user(".$user->GetJID('full').") \n");

	my $control_id;
	# Message Types
	# Using user with resource for normal and chat. Not even sure about headline or error.
	if ( $type eq 'normal' || $type eq '' )
	{
  		$control_id = $user->GetJID('full').'-'.$type;
	}
	elsif ( $type eq 'chat' )
	{
  		$control_id = $user->GetJID('full').'-'.$node->GetThread;
	}
	elsif ( $type eq 'groupchat' )
	{
		# chatroom should not use the resource
  		$control_id = $user->GetJID('base').'-'.$type;
	}
	elsif ( $type eq 'headline' )
	{
  		$control_id = $user->GetJID('full').'-'.$type;
	}
	elsif ( $type eq 'error' )
	{
  		$control_id = $user->GetJID('full').'-'.$type;
	}
	# IQ, treat like a normal message
	elsif ( $type eq 'get' )
	{
  		$control_id = $user->GetJID('full').'-'.$type;
	}

	else
	{
  		$self->Verbose("GetControlForNode: BAD TYPE ignoring node");
  		return(undef);
	}

	my $control = $self->GetControl($control_id, $user->GetJID('base'), $user_protocol);

	# If not auth, no control,
	unless ($control)
	{
		$self->Verbose("GetControlForNode: No Control!!!!");
		return (0);
	};

    $self->Verbose( "GetControlForNode: Control ".$control_id." on input from ".$user." \n",2);

	# These are not part of the default control attributes set by GetControl.
	# TODO don't reset every time.
	$control->set_jid($user);
	$control->type($type);

  return ( $control );

} # End GetControlForNode

=item Peers

This POE event handler performs the transport end of the peer manipulation
commands, such as add peer. It takes an action, a User object and an optional
Request object as arguments.

Valid actions are add and delete. Currently delete does not force a log
off from a chatroom, but it might if I fix that and forget to update the docs.

=cut

sub Peers {
	my ($kernel,  $self, $action, $user, $request) =
	  @_[KERNEL, OBJECT,  ARG0,   ARG1, 	ARG2];

	# either we're given a user or just the id
	my $id = ref($user) =~ /User/i ? $user->id : $user;

    $self->Verbose("Peers: $action ".$id );

	my $txt = '';
	my $code;

	# lets see how it goes....
	if ($action eq 'add' && ref($user) =~ /User/i )
	{
		eval { 	$self->push_peers($user); };

		if( $@ )
		{
			$self->Verbose("Peers: self->push_peers(".$user->id.") got (".$@.') ');
			$txt = "Invalid user ".$user->id." : $@ !";
			$code = 400;
		}
		else
		{
			$txt = $action." ".$user->id." successful. ";
			$code = 200;
			$kernel->yield('JoinPeerRooms');
		}
	}
	elsif ($action eq 'delete')
	{
		my $i = 0;
		# loop over the users and remove the matching one.

		PEER: foreach my $peer ( @{$self->peers} )
		{
			if ( $peer->id eq $id  )
			{
				splice( @{$self->peers},$i,1);

				# TODO we need a separate remove control command
				if ( defined( $self->controls ) &&
					exists( $self->controls->{ $id.'-groupchat' } ) )
				{
					delete( $self->controls->{ $id.'-groupchat' } );
				}
				$txt = $action." ".$user->id." successful. ";
				$code = 200;
				last PEER;
			}
			$i++;
		}
	}

	if( $txt eq '' )  # we didn't do anything
	{
		$txt = $action." on ".$id." failed. ";
		$code = 400;
	}

	$self->Verbose('Peers: txt('.$txt.') code('.$code." )",2);

	if ($request)
	{
		$request->Respond($kernel, $txt, $code);
		return;
	}
}

sub Address {
	my $self = shift;

	my $sock = $self->xmpp->{STREAM}->GetSock( $self->xmpp->GetStreamID );
	my ($port, $naddr) = sockaddr_in(getsockname($sock));
	my $addr = inet_ntoa($naddr);

	$self->Verbose("Address: $addr");

	return ($addr);
}
1;

#__END__


=back

=head1 AUTHOR

Eric Hacker	 hacker can be emailed at cpan.org

=head1 BUGS

SHOULDS and MUSTS are currently not enforced.

New commands could clobber old ones under certain circumstances.

Test scripts not thorough enough.

Probably many others.

=head1 LICENSE

Copyright (c) 2007, Alcatel Lucent, All rights resevred.

This package is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=cut
