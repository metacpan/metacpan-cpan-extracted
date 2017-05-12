package Agent::TCLI::Package::XMPP;
#
# $Id: XMPP.pm 59 2007-04-30 11:24:24Z hacker $
#
=pod

=head1 NAME

Agent::TCLI::Package::XMPP - A package of commands to access the XMPP transport

=head1 SYNOPSIS

	# Within a TCLI Agent script

	use Agent::TCLI::Transport::XMPP;
	use Agent::TCLI::Package::XMPP;

	my @packages = (
		Agent::TCLI::Package::XMPP->new(),
	);

	Agent::TCLI::Transport::XMPP->new(
	    'control_options'	=> {
		    'packages' 		=> \@packages,
	     },
	);


=head1 DESCRIPTION

This package provides commands for the control of the XMPP Transport from
within a TLCI Agent. One would typically want to have this command package
loaded when using the XMPP Transport, but it is not required.

This is still poorly documented. I apologize for the inconvenience.

=head1 INTERFACE

=cut

use warnings;
use strict;

use POE;
use Agent::TCLI::Command;
use Agent::TCLI::Parameter;
use Agent::TCLI::User;
use Getopt::Lucid qw(:all);

use Object::InsideOut qw(Agent::TCLI::Package::Base);

our $VERSION = '0.030.'.sprintf "%04d", (qw($Id: XMPP.pm 59 2007-04-30 11:24:24Z hacker $))[2];

=head2 ATTRIBUTES

The following attributes are accessible through standard <attribute>
methods unless otherwise noted.

These attrbiutes are generally internal and are probably only useful to
someone trying to enhance the functionality of this Package module.

=cut

=head2 METHODS

Most of these methods are for internal use within the TCLI system and may
be of interest only to developers trying to enhance TCLI.

=over

=item new ( hash of attributes )

Usually the only attributes that are useful on creation are the
verbose and do_verbose attrbiutes that are inherited from Agent::TCLI::Base.

=cut

sub _preinit :Preinit {
	my ($self,$args) = @_;

	$args->{'name'} = 'tcli_xmpp';

  	$args->{'session'} = POE::Session->create(
      object_states => [
          $self => [qw(
          	_start
          	_stop
          	_shutdown
          	_default

			change
			establish_context
			peer
			show
			shutdown
			)],
      ],
  	);

  	$args->{'opt_args'} = [qw( group_mode group_prefix verbose )];

}

sub _init :Init {
	my $self = shift;

	$self->Verbose("init: loading parameters and commands" );

	$self->LoadYaml(<<'...');
---
Agent::TCLI::Parameter:
  name: peers
  help: list the peers
  manual: >
    This debugging parameter can be used to list the peers currently
    loaded in a transport.
  type: Switch
---
Agent::TCLI::Parameter:
  name: controls
  help: list the controls
  manual: >
    This debugging parameter can be used to list the controls currently
    loaded in a transport.
  type: Switch
---
Agent::TCLI::Parameter:
  name: xmpp_verbose
  aliases: verbose|v
  constraints:
    - UINT
  help: an integer for verbosity
  manual: >
    This debugging parameter can be used to adjust the verbose setting
    for the XMPP transport.
  type: Counter
---
Agent::TCLI::Parameter:
  name: group_mode
  constraints:
    - ASCII
  help: sets how the control processes group chats
  manual: |
    The group_mode tells the control how to determine if a group chat
    message is directed at itself. The possible settings are:
        all - treat everything from others as a command
        log - ignore everything from others, only use chatroom for logging
        named - only accept commands prefixed by the name followed by a colon
        prefixed - only accept commands prefixed by the group_prefix,
          by default a colon
  type: Param
---
Agent::TCLI::Parameter:
  name: group_prefix
  constraints:
    - ASCII
  help: sets the prefix used in group chats
  manual: >
    The group_prefix sets the prefix used by the group_mode prefixed option.
    By default, it is a colon.
  type: Param
---
Agent::TCLI::Parameter:
  name: id
  constraints:
    - ASCII
  help: the user id
  manual: >
    ID of user in a form acceptable to the protocol.
    XMPP/Jabber IDs MUST not include resource information.
  type: Param
---
Agent::TCLI::Parameter:
  name: auth
  constraints:
    - ASCII
  help: Authorization level of user.
  manual: |
    Authorization level of user. MUST be one of these values:
      reader - has read access
      writer - has write access
      master - has root access
      logger - receives copies of all messages, can't do anything

    Note that commands must choose from the above to determine if a user can
    do anything. Not very robust, but hey, it's not even 1.0 yet.

    Every user should be defined with an B<auth>, but currently this is not
    being checked anywhere.
  type: Param
---
Agent::TCLI::Parameter:
  name: protocol
  constraints:
    - ASCII
  help: Protocol that user is allowed access on.
  manual: >
    Protocol that user is allowed access on. Currently only xmpp and
    xmpp-groupchat are supported by Transport::XMPP. If the protocol
    is xmpp-groupchat, the Transport will automatically join the
    conference room when the user is added.
  type: Param
---
Agent::TCLI::Parameter:
  name: password
  constraints:
    - ASCII
  help: A password for the user.
  manual: >
    A password for the user. For a private XMPP chatroom,
    this is used to log on. It is not used anywhere else currently.
  type: Param
---
Agent::TCLI::Command:
  call_style: session
  command: tcli_xmpp
  contexts:
    ROOT:
      - jabber
      - xmpp
  handler: establish_context
  help: 'manipulate the jabber/xmpp transport'
  manual: >
    This command allows one to control various aspects of the XMPP
    transport.
  name: xmpp
  topic: admin
  usage: xmpp change group_mode prefixed
---
Agent::TCLI::Command:
  name: change
  call_style: session
  command: tcli_xmpp
  contexts:
    jabber: change
    xmpp: change
  handler: change
  help: 'change the jabber/xmpp transport parameters'
  manual: >
    This command allows one to change one of several different parameters
    that control the operation of the XMPP transport.
  parameters:
    group_mode:
    group_prefix:
    xmpp_verbose:
  topic: admin
  usage: xmpp change group_mode prefixed
---
Agent::TCLI::Command:
  name: show
  call_style: session
  command: tcli_xmpp
  contexts:
    jabber: show
    xmpp: show
  handler: show
  help: 'show the jabber/xmpp transport settings'
  manual: >
    This command will show the current setting for parameters
    that control the operation of the XMPP transport. One can use all
    to see all the parameters.
  parameters:
    group_mode:
    group_prefix:
    xmpp_verbose:
    controls:
    peers:
  topic: admin
  usage: xmpp show group_mode
---
Agent::TCLI::Command:
  name: shutdown
  call_style: session
  command: tcli_xmpp
  contexts:
    jabber: shutdown
    xmpp: shutdown
  handler: shutdown
  help: 'shutdown the jabber/xmpp transport'
  topic: admin
  usage: xmpp shutdown
---
Agent::TCLI::Command:
  name: peer
  call_style: session
  command: tcli_xmpp
  contexts:
    jabber: peer
    xmpp: peer
  handler: establish_context
  help: 'manage peers that the transport talks to'
  manual: >
    The peer command allows one to add or delete users from the list of
    peers that the Transport will communicate with. Currently this list of
    peers is not savable.
  topic: admin
  usage: xmpp peer add id=peer@example.com protocol=xmpp auth=master
---
Agent::TCLI::Command:
  call_style: session
  command: tcli_xmpp
  contexts:
    jabber:
      peer: add
    xmpp:
      peer: add
  handler: peer
  help: 'add peers that the transport talks to'
  manual: >
    The peer command allows one to add or delete users from the list of
    peers that the Transport will communicate with. Currently this list of
    peers is not savable.
  name: peer-add
  parameters:
    auth:
    id:
    password:
    protocol:
  required:
    auth:
    id:
    protocol:
  topic: admin
  usage: xmpp peer add id=peer@example.com protocol=xmpp auth=master
---
Agent::TCLI::Command:
  call_style: session
  command: tcli_xmpp
  contexts:
    jabber:
      peer: delete
    xmpp:
      peer: delete
  handler: peer
  help: 'delete peers that the transport talks to'
  manual: >
    The delete command allows one to delete users from the list of
    peers that the Transport will communicate with. When the user is
    deleted, they will not be able to begin new sessions, but existing
    sessions may continue. The delete command will accept all the same
    parameters as the add command, although it ignores everything
    but the id.
  name: peer-delete
  parameters:
    auth:
    id:
    password:
    protocol:
  required:
    id:
  topic: admin
  usage: xmpp peer add id=peer@example.com protocol=xmpp auth=master
...

}

=item peer

This POE event handler executes the peer commands.

=cut

sub peer {
    my ($kernel,  $self, $sender, $request, ) =
      @_[KERNEL, OBJECT,  SENDER,     ARG0, ];

	# It seems that the proper way to handle removing users would be to delete
	# the user's control and making sure that the user is authenticated before
	# starting up a new control. There needs to be a remove control capability
	# within a transport.

	my $txt = '';
	my $param;
	my $command = $request->command->[0];
	my $cmd = $self->commands->{'peer-'.$command};

	# break down args
	return unless ( $param = $cmd->Validate($kernel, $request, $self) );

	$self->Verbose("peer: param dump",4,$param);

	my $user = Agent::TCLI::User->new($param
	);

	if ($user)
	{
		$kernel->post('transport_xmpp' => 'Peers' =>
			$command,
			$user,
			$request
		);
	}
	else
	{
		$request->respond($kernel, "peer $command failed ", 417);
	}

	return ($self->name.":peer")
}

=item change

This POE event handler executes the change command.

=cut

sub change {
    my ($kernel,  $self, $sender, $request, ) =
      @_[KERNEL, OBJECT,  SENDER,     ARG0, ];

	my $cmd = $self->commands->{'change'};

	# break down args
	return unless ( my $param = $cmd->Validate($kernel, $request, $self) );

	$self->Verbose("change: param dump",4,$param);

	$self->Verbose("settings: sending params to transport_xmpp",2);
	$kernel->post('transport_xmpp' => 'Set' =>
			$param => $request );

}

=item show

This POE event handler executes the show commands.

=cut

sub show {
    my ($kernel,  $self, $sender, $request, ) =
      @_[KERNEL, OBJECT,  SENDER,     ARG0, ];
	$self->Verbose("show: request ".$request->id );

	my ($txt, $subtxt, $what);
	# calling with show as a context
	if ( $request->command->[0] ne 'show'  )  # cmd1 show settings
	{
		$what = $request->command->[0];
	}
#	elsif ( $request->command->[0] eq 'show'  # cmd1 settings show??? Not enabled
#		&&  $request->command->[1] ne 'cmd1' )
#	{
#		$what = $request->command->[1];
#	}
	# calling with show as a command, that is the handler for show is show.
	elsif ( $request->command->[0] eq 'show' ) 	# cmd1 show arg
												# cmd1 attacks show <arg>
	{
		$what = $request->args->[0];
	}

	foreach my $attr ( keys %{$self->commands->{'show'}->parameters} )
	{
		if ( $what eq $attr || $what =~ qr(^(\*|all)$) )
		{
			$self->Verbose("show: sending show attr($attr) to transport_xmpp");
			$kernel->post('transport_xmpp' => 'Show' => $attr =>
				=> $request );
			return;
		}
		else
		{
	  		$txt = "Can't display ".$attr
		}
	}

  	if (!defined($txt) || $txt eq '' )
  	{
  		$txt = "No entries for ".$what
  	}

	$request->Respond($kernel, $txt);
}

=item shutdown

This POE event handler executes the shutdown command.

=cut

sub shutdown {
    my ($kernel,  $self, $sender, $request, ) =
      @_[KERNEL, OBJECT,  SENDER,     ARG0, ];
	$self->Verbose("shutdown: request ".$request->id );

	$self->Verbose("shutdown: sending shutdown to transport_xmpp");
	$request->Respond($kernel, "Shutting down transport_xmpp");
	$kernel->post('transport_xmpp' => '_shutdown');
}

=item start

This POE event handler executes the start command. It is not exactly clear
when this would be useful currently, but we have a shutdown command and
balance must be maintained. Hopefully other transports will be available
in the future and this command might be more useful.

=back

=cut

sub start {
    my ($kernel,  $self, $sender, $request, ) =
      @_[KERNEL, OBJECT,  SENDER,     ARG0, ];
	$self->Verbose("start: request ".$request->id );

	$self->Verbose("start: sending start to transport_xmpp");
	$request->Respond($kernel, "Starting transport_xmpp");
	$kernel->post('transport_xmpp' => '_start');
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

Test scripts not thorough enough.

Probably many others.

=head1 LICENSE

Copyright (c) 2007, Alcatel Lucent, All rights resevred.

This package is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=cut
