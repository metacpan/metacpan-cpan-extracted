package Agent::TCLI::Control;
# $Id: Control.pm 62 2007-05-03 15:55:17Z hacker $

=pod

=head1 NAME

Agent::TCLI::Control - Manage TCLI commands

=head1 SYNOPSIS

Controls are spawned from within Transports. One does not need to
manipulate to create typical Agents.
Control is very poorly documented at this point.
I apologize for the inconvenience.

=head1 DESCRIPTION

Why is it that people like GUIs so much? One of the reasons is because a
good GUI allows people to spend less time memorizing the syntax and
language specifics within a program. If one has no clue what a particular
command is, one can still check out all the menus until something is found.

With a command line, this type of hunt and peck is more difficult, but not
impossible. The command line must be command contextual to do this. A typical
operating system interface maintains a file system context and not a
command context. Cisco IOS and other network equipment often use a command
contextual interface, and this is sometimes called Cisco-like.
Network equipment usually has a much simpler file system
and Network Administrators are usually forced to manage many more types of
devices than System Administrators. Network Systems also generally require much less
daily contact, so it is important for the user interface to be as helpful
as possible, because the operator has likely forgotten half of the command
syntax.

For functional quality assurance testing, the demands are much more in line with Network
Administration. One will need to plug in a module that tests some sort
of capability, write and run some tests, and then do something else for
a bit while the developers/integrators fix the problems. Thus TCLI attempts
to use the Cisco-like contextual paradigm to provide a user interface to
support testers.

=cut

use warnings;
use strict;

use POE;
use Carp;

use Object::InsideOut qw(Agent::TCLI::Package::Base);
use Agent::TCLI::Request;
use Agent::TCLI::Response;
use Agent::TCLI::Command;
use Agent::TCLI::Parameter;
use Params::Validate;
#use Data::Dump qw(pp);
use Text::ParseWords;

#sub VERBOSE () { 0 }

our $VERSION = '0.030.'.sprintf "%04d", (qw($Id: Control.pm 62 2007-05-03 15:55:17Z hacker $))[2];

=head1 INTERFACE

=head2 ATTRIBUTES

The following attributes are accessible through standard accessor/mutator
methods and may be set as a parameter to new unless otherwise noted.

=over

=item id

ID of control. MUST be unique to all other controls and is the POE kernel alias.

=cut
my @id 			:Field
				:All('id');

=item registered_commands

The collection of registered_commands in the control library. Commands may
not be set, but must added with the register method.

=cut

my @registered_commands 	:Field	:Get('registered_commands');

my @starts 		:Field	:Get('starts');

my @stops 		:Field	:Get('stops');

my @handlers 	:Field	:Get('handlers');

my @start_time	:Field
				:Get('start_time');

my @user		:Field  :All('user')
				:Type('Agent::TCLI::User');

my @packages	:Field	:All('packages');

#my @alias		:Field	:All('alias');

=item auth

Authorization for the user for this control. Must be separate from the
auth in the user object since that might not be the only factor at all times.

=cut
my @auth 		:Field
				:All('auth');

=item type

Type of conversation. MUST be one of these values:
  B<instant> =>  one time (or not specified)
  B<chat>  =>  peer to peer chat
  B<group>  =>  group chatroom

=cut
my @type 	:Field( 'All' => 'type' );

=item context

Contains the context of the current Command application for the control.

=cut
my @context 	:Field
				:Type('Array')
				:Arg('Name' => 'context', 'Default' => ['ROOT'] )
				:Acc('context');

=item owner

Contains the owning session of the control. This allows the control to be
passed around between sessions and whatever session that has it can
send back to the top level originating session.

=cut
my @owner 		:Field( 'All' => 'owner' );

=item prompt

The promt that the control is displaying, when appropriate.

=cut
my @prompt		:Field  :All('prompt');

=item local_address

The local IP address of the system

=cut
my @local_address	:Field
					:All('local_address');

=item hostname

The hostname being used by the control.

=cut
my @hostname		:Field
					:All('hostname');

=item poe_debug

A flag to set whether to enable poe debugging if installed

=cut
my @poe_debug		:Field
					:All('poe_debug');

# Holds our session data. Made weak per Merlyn
# http://poe.perl.org/?POE_Cookbook/Object_Methods.
# We also don't take session on init.
#my @session			:Field
#					:Get('session')
#					:Weak;

# Standard class utils are inherited
=back

=head2 METHODS

=over

=cut

sub _preinit :Preinit {
	my ($self,$args) = @_;

  	$args->{'session'} = POE::Session->create(
		object_states => [
          $self => [qw(
          	_start
          	_stop
          	_shutdown
          	_default
          	ControlAddState
          	control_presence

         	AsYouWished
          	ChangeContext
          	Execute

			dumpcmd
			establish_context
			exit
          	general
          	help
          	manual
          	net
          	show
          	settings
			)],
      ],
      'heap' => $self,
  	);
}

sub _init :Init {
	my $self = shift;

  # Validate arguments
#  $self->Verbose( "spawn: Validating arguments \n" );

#  my %args = validate( @_, {
#	local_address  	=> { optional => 1 },
#	local_port     	=> { optional => 1, default => 42 },
#	hostname       	=> { optional => 1, default => hostname() },
#	poe_debug      => { optional => 1, default => 1 },
#                       # if not available, silenty fails to load debug
#    }
#  );

   	$self->LoadXMLFile();

	# Register default commands
	$self->Verbose( "init: Registering default commands \n".$self->dump(1),3 );

	foreach my $cmd ( values %{ $self->commands } )
	{
		$self->RegisterCommand($cmd);
	}

	# if available, register requested command packages
	$self->Verbose( "init: Registering user packages \n" );

	if ( defined($packages[$$self] ) )
	{
		my $txt;
		foreach my $package (@{ $packages[$$self] })
		{
			my $txt = $self->RegisterPackage($package);
        	croak ($txt) if ($txt); # Load fail on start MUST die.
		}
	} # end if packages

  # Register user commands, if requested #{{{
#  $self->Verbose( "init: Registering user commands \n" );
#
#  if( ref( $commands[$$self] ) =~ /ARRAY/i ) {
#
#	foreach my $cmd (@{ $commands[$$self] }) {
#    	if ( ref($cmd) eq 'HASH') {
#			$self->register($cmd);
#    	} elsif ( ref($cmd) =~ /Agent::TCLI::Command/ ) {
#			$self->register_command($cmd);
#    	} else {
#			$self->Verbose("init: Parameter 'commands' contains bad element");
#			$self->Verbose("init: Dump of commands ", 4, $commands[$$self]);
#  		}
#	} #end foreach
#
#  } else {
#
#	$self->Verbose("init: User commands not an array ref, not loaded");
#	$self->Verbose("init: Dump of commands ", 4, $commands[$$self]);
#
#  } #end if commands

	if ( defined( $hostname[$$self] ) )
	{
  		$self->set(\@prompt, $id[$$self]." [".$hostname[$$self]."]: ");
	}
}

=item Register

Register is an internal object method used to register commands with the Control.

=cut

sub Register {
    my $self = shift;
	$self->Verbose("Register: params",4,@_);
    my %cmd = validate( @_, {
        help => { type => Params::Validate::SCALAR },  #required
        usage     => { type => Params::Validate::SCALAR },  #required
        topic     => { optional => 1, type => Params::Validate::SCALAR },
        name      => { type => Params::Validate::SCALAR },  #required
        command   => { type => ( Params::Validate::SCALAR | Params::Validate::CODEREF ) }, #required
        contexts	  => { optional => 1, type => Params::Validate::HASHREF },
        call_style     => { optional => 1, type => Params::Validate::SCALAR },
#        start     => { optional => 1, type => Params::Validate::CODEREF },
        handler   => { optional => 1, type => Params::Validate::SCALAR },
#        stop      => { optional => 1, type => Params::Validate::CODEREF },
    } );

	# Set up a default contexts if one not provided.
    $cmd{'contexts'} = { 'ROOT' => $cmd{'name'} } unless (defined ( $cmd{'contexts'}) );

	$self->Verbose("Register: name ".$cmd{'name'} );

	$self->RegisterContexts(\%cmd);

#	# Don't want these in loop, since they only should get added once.
#    push ( @{ $starts[$$self] },   \%cmd )  if ( defined ( $cmd{'start'} ) );
#    push ( @{ $handlers[$$self] }, \%cmd )  if ( defined ( $cmd{'handler'} ) );
#    push ( @{ $stops[$$self] },    \%cmd )  if ( defined ( $cmd{'stop'} ) );

	$self->Verbose("Register: commands \n",5,$registered_commands[$$self]);

    return 1;
}

=item RegisterContexts

RegisterCotexts is an internal object method used to register contexts for
commands with the Control.

=cut

sub RegisterContexts {
	my ($self, $cmd ) = @_;
	$self->Verbose( "RegisterContext: (".$cmd->name.") ");

	# TODO Error catching
	# Loop over each context key to add command to list
   	foreach my $c1 ( keys %{ $cmd->contexts } )
   	{
   		my $v1 = $cmd->contexts->{$c1};
  		# Not warning on error if 'ROOT' and hash
   		if ( ( $c1 ne 'ROOT' ) && ( ref( $v1 ) =~ /HASH/ ) )
   		{
   			foreach my $c2 ( keys %{ $v1 } )
   			{
   				my $v2 = $v1->{$c2};
   				if ( ref( $v2 ) =~ /HASH/ )
   				{
		   			foreach my $c3 ( keys %{ $v2 } )
		   			{
						my $v3 = $v2->{$c3};
						if ( $c3 eq '.' )
						{
							$self->Verbose( "RegisterContext:3.: Adding command "
							.$v3." in context ".$c1."->".$c2." ");
							$registered_commands[$$self]{ $c1 }{ $c2 }{ $v3 }{'.'} = $cmd;
						}
						else
						{
							$self->Verbose( "RegisterContext:3: Adding command "
								.$v3.
								" in context ".$c1."->".$c2."->".$c3);
							$registered_commands[$$self]{ $c1 }{ $c2 }{ $c3 }{ $v3 }{'.'} = $cmd;
						}
		   			}
  				}
		   		elsif ( ( ref( $v2 ) =~ /ARRAY/ ) )
				{
					foreach my $v2c ( @{$v2})
					{
						$self->Verbose( "RegisterContext:2a: Adding command "
						.$v2c." in context ".$c1."->".$c2." ");
						$registered_commands[$$self]{ $c1 }{ $c2 }{ $v2c }{'.'} = $cmd;
					}
				}
				elsif ( $c2 eq '.' )
				{
					$self->Verbose( "RegisterContext:2.: Adding command "
					.$v2." in context ".$c1."->");
					$registered_commands[$$self]{ $c1 }{ $v2 }{'.'} = $cmd;
				}
   				else
   				{
					$self->Verbose( "RegisterContext:2: Adding command "
						.$v2.
						" in context ".$c1."->".$c2." ");
					$registered_commands[$$self]{ $c1 }{ $c2 }{ $v2 }{'.'} = $cmd;
   				}
   			}
   		}
   		elsif ( ( ref( $v1 ) =~ /ARRAY/ ) )
		{
			foreach my $v1c ( @{$v1})
			{
				$self->Verbose( "RegisterContext:1a: Adding command "
				.$v1c." in context ".$c1." ");
				$registered_commands[$$self]{ $c1 }{ $v1c }{'.'} = $cmd;
			}
		}
		else
		{
			$self->Verbose( "RegisterContext:1: Adding command "
			.$v1." in context ".$c1." ");
			$registered_commands[$$self]{ $c1 }{ $v1 }{'.'} = $cmd;
		}
    }
	return 1;
}

=item FindCommand

FindCommand is an internal object method used to parse the command line
arguments and determine the appropriate command handler.

=cut

sub FindCommand {
	my ($self, $args ) = @_;
	$self->Verbose("FindCommand: Got args for ".$id[$$self]." in context ".
		$self->print_context." \n",2,$args);

	my (@c, $cmd, $txt, $code, $thisdepth);

	my $depth; 	# How deep are we in already. Don't want to be searching
				# deeper than we should.

    # regex matches on /non-whitespace followed by none or more whitespace
    if ( $args->[0] =~ /^\/(\S+)\s*/ )
    {
	    # Special command option to backout context
	    # We won't process whole context trees (../cmd) but we should
	    # allow a root context to get out of poorly coded commands or whatnot
	    # as a one time option. Hey Cisco, can you do that?
        $args->[0] = $1;
        $self->Verbose( "FindCommand: Root context called, now using ".
          $args->[0]." from root\n" );
 		push ( @c, @{$args} );
    	$depth = 0;
    }
    elsif ( $args->[0] eq '/' && scalar( @{$args} ) > 1 )
    {
        # similar to above, except as a separate arg. Used by Request objects
        # to indicate that context should be ignored. args of a single
        # '/' is handled as a context shift command and not temporary.
        # also used by help for lookup.
        shift (@{$args});
        $self->Verbose( "FindCommand: Root context called, now using ".
          $args->[0]." from root\n" );
 		push ( @c, @{$args} );
    	$depth = 0;
    }
	else
	{
		# We need to mash up context and args to find out what we're supposed to do.
		$depth = $self->depth_context;
		@c = @{ $self->context } unless ($depth == 0);
		push ( @c, @{$args} );
		$self->Verbose("FindCommand: depth(".$depth.') and @c'." \n",3,\@c);
	}

	$self->Verbose("FindCommand: current registered_commands hash \n",4,$registered_commands[$$self]);

	# Try to find a match for the context and args in the command hash

	# thisdepth will tell us how deep we found something ,or if we didn't
	$thisdepth = -5;

	# try first four combined args
	if ( defined($c[2]) &&
		defined($registered_commands[$$self]{$c[0]} ) &&
		defined($registered_commands[$$self]{$c[0]}{$c[1]} ) &&
		defined($registered_commands[$$self]{$c[0]}{$c[1]}{$c[2]} )
		)
	{
		if ( defined($c[3]) &&
			defined($registered_commands[$$self]{$c[0]}{$c[1]}{$c[2]}{$c[3]} )
			)
		{
			$cmd =
			$registered_commands[$$self]{$c[0]}{$c[1]}{$c[2]}{$c[3]}{'.'};
			$thisdepth = 3;
		}
		# All handler
		elsif ( defined($c[3]) &&
			defined($registered_commands[$$self]{$c[0]}{$c[1]}{$c[2]}{'ALL'} )
			)
		{
			$cmd =
			$registered_commands[$$self]{$c[0]}{$c[1]}{$c[2]}{'ALL'}{'.'};
			$thisdepth = 3;
		}
		# Universal in this context
		elsif ( defined($c[3]) &&
			defined($registered_commands[$$self]{$c[0]}{$c[1]}{'GROUP'}) &&
			defined($registered_commands[$$self]{$c[0]}{$c[1]}{'GROUP'}{$c[3]})
			)
		{
			$cmd =
			$registered_commands[$$self]{$c[0]}{$c[1]}{'GROUP'}{$c[3]}{'.'};
			$thisdepth = 3;
		}
		# $c[3] globally Universal
		elsif ( defined($c[3]) &&
			defined($registered_commands[$$self]{'UNIVERSAL'}{$c[3]} )
			)
		{
			$cmd =
			$registered_commands[$$self]{'UNIVERSAL'}{$c[3]}{'.'};
			$thisdepth = 3;
		}
		elsif (
		 	defined($registered_commands[$$self]{$c[0]}{$c[1]}{$c[2]}{'.'} )
			)
		{
			$cmd =
			$registered_commands[$$self]{$c[0]}{$c[1]}{$c[2]}{'.'};
			$thisdepth = 2;
		}
		else
		{
			$thisdepth = -4;
		}
	}

	if ( $thisdepth < 0 && defined($c[1]) && $depth <= 2 &&
		defined($registered_commands[$$self]{$c[0]} ) &&
		defined($registered_commands[$$self]{$c[0]}{$c[1]} )
		)
	{
		# All handler
		if ( defined($c[2]) &&
			defined($registered_commands[$$self]{$c[0]}{$c[1]}{'ALL'})
			)
		{
			$cmd =
			$registered_commands[$$self]{$c[0]}{$c[1]}{'ALL'}{'.'};
			$thisdepth = 2;
		}
		 # Universal in this context
		elsif ( defined($c[2]) &&
			defined($registered_commands[$$self]{$c[0]}{'GROUP'} ) &&
			defined($registered_commands[$$self]{$c[0]}{'GROUP'}{$c[2]} )
			)
		{
			$cmd =
			$registered_commands[$$self]{$c[0]}{'GROUP'}{$c[2]}{'.'};
			$thisdepth = 2;
		}
		# $c[2] globally Universal
		elsif ( defined($c[2]) &&
			defined($registered_commands[$$self]{'UNIVERSAL'}{$c[2]} )
			)
		{
			$cmd =
			$registered_commands[$$self]{'UNIVERSAL'}{$c[2]}{'.'};
			$thisdepth = 2;
		}
		elsif ( defined($registered_commands[$$self]{$c[0]}{$c[1]}{'.'} )
			)
		{
			$cmd =
			$registered_commands[$$self]{$c[0]}{$c[1]}{'.'};
			$thisdepth = 1;
		}
		else
		{
			$thisdepth = -3;
		}
	}

	if ( $thisdepth < 0 && defined($c[1]) && $depth <= 1 &&
		defined($registered_commands[$$self]{$c[0]} )
		)
	{
		 # All handler
		if (
			defined( $registered_commands[$$self]{$c[0]}{'ALL'} )
			)
		{
			$cmd =
			$registered_commands[$$self]{$c[0]}{'ALL'}{'.'};
			$thisdepth = 1;
		}
		# Universal context
		elsif (
			defined( $registered_commands[$$self]{'GROUP'}{$c[1]}
			) )
		{
			$cmd =
			$registered_commands[$$self]{'GROUP'}{$c[1]}{'.'};
			$thisdepth = 1;
		}
		# $c[1] Globally Universal
		elsif (
			defined($registered_commands[$$self]{'UNIVERSAL'}{$c[1]} )
			)
		{
			$cmd =
			$registered_commands[$$self]{'UNIVERSAL'}{$c[1]}{'.'};
			$thisdepth = 1;
		}
		else
		{
			$thisdepth = -2;
		}
	}

	if ( $thisdepth < 0 && defined($c[0]) && $depth == 0 )
	{
		# Root context
		if ( defined($registered_commands[$$self]{'ROOT'}{$c[0]} )
			)
		{
			$cmd =
			$registered_commands[$$self]{'ROOT'}{$c[0]}{'.'};
			$thisdepth = 0;
		}
		# There is no 'ALL' handling at the root context. Make a case and I'll consider it.
		# There is no Universal only in root context. Make a case and I'll consider it.

		# Globally Universal
		elsif ( defined(
			$registered_commands[$$self]{'UNIVERSAL'}{$c[0]}
			) )
		{
			$cmd =
			$registered_commands[$$self]{'UNIVERSAL'}{$c[0]}{'.'};
			$thisdepth = 0;
		}
		else
		{
			$thisdepth = -1;
		}
	}

	# Might use thisdepth later to determine better response.
	if ( $thisdepth < 0 )
	{
			$txt .= "Command '".join(' ',@{$args})."' not found";
			$code = 404;
			$cmd = undef;
			$self->Verbose("FindCommand: ".$txt.
				") code ($code) thisdepth(".$thisdepth.") \n");
			$self->Verbose("FindCommand: working c array \n",2,\@c);
			$self->Verbose("FindCommand: current registered_commands hash \n",2,$registered_commands[$$self]);
	}

	unless ( $txt )
	{
		$self->Verbose("FindCommand: thisdepth($thisdepth) \n",3,\@c);

		# take off the args, but leave the command and the context.
		@{$args} = splice(@c,$thisdepth+1);

		$self->Verbose("FindCommand: Found(".$cmd->name.
			") for ".$id[$$self]." with thisdepth($thisdepth) args\n",2,$args);
		# always return something defined.
		$txt = '';
		$code = 200;
	}
	# we want @commands to be reversed.
	@c = reverse(@c);
	return($cmd, \@c, $txt, $code);
}

=item SortCommands

SortCommands is an internal object method used to sort the commands available
in a context. It returns an array of arrays of alias => cmd object.

=cut

sub SortCommands {
	my ($self, $hash ) = @_;
	my @cmds;

	$self->Verbose("SortCommands: hash dump \n",2,$hash);

	# one must remember that the command name is not the alias that
	# might be in use in this context. Thus we muct return an array
	# of arrays so that we have both the alias and the cmd object.

	foreach my $command ( sort keys %{$hash} )
	{
		push (@cmds, [ $command => $hash->{$command}{'.'}  ] )
			if ( $command !~ qr(^GROUP|^\.) ); # Ignore .objects and GROUP
	}

	return (\@cmds);
}

=item ListCommands

ListCommands is an internal object method used to list the commands available
in a context. It calls SortCommands once it has found the right context.

=cut

sub ListCommands {
	my ($self, $c ) = @_;

    if ( defined($c) && ref($c) eq 'ARRAY' && $c->[0] eq '/' )
    {
        shift (@{$c});
        $self->Verbose( "ListCommand: Root context stripped '/' ");
	}

	my $depth = defined($c) && ref($c) eq 'ARRAY' ? scalar(@{$c}) : 0;
	if ( $depth == 0 )  # Use current context if none supplied
	{
		$c = $self->context;
		$depth = $self->depth_context;
	}

	$self->Verbose("ListCommand: depth(".$depth.") \n",2,$c);

	$self->Verbose("ListCommand: current registered_commands hash \n",4,$registered_commands[$$self]);

	my (%cmds, $txt, $code, $thisdepth);

	my @aliases;

	# All* handler contexts are not handled because that doesn't make sense here.

	# This is simlar in structure to Command::Command::Usages so any major
	# issues here probably need to be addressed there as well.

	# Root context
	if ( $c->[0] eq '/' && defined( $registered_commands[$$self]{'ROOT'} ) )
	{
		# This would allow hashes under / which is not supported by Control.pm
		push( @aliases , @{ $self->SortCommands( $registered_commands[$$self]{'ROOT'} ) } );
	}
	# Global context. Only return if asked for.
	elsif ( $c->[0] eq '*' && defined( $registered_commands[$$self]{'UNIVERSAL'} ) )
	{
		# This would allow hashes under * which is not supported by Control.pm
		push( @aliases , @{ $self->SortCommands( $registered_commands[$$self]{'UNIVERSAL'} )  } );
	}
	elsif ( @{$c} == 1 )
	{
		if ( defined( $registered_commands[$$self]{ $c->[0] } ) )
		{
			push( @aliases , @{ $self->SortCommands( $registered_commands[$$self]{ $c->[0] } ) } );
		}

# There are no groups allowed at this level currently
#		elsif ( defined( $registered_commands[$$self]{ 'GROUP' } ) )
#		{
#			$aliases =  $self->SortCommands( $registered_commands[$$self]{ 'GROUP' } );
#		}
	}
	elsif ( @{$c} == 2 )
	{
		if ( defined( $registered_commands[$$self]{ $c->[0] }{ $c->[1] } ) )
		{
			push( @aliases , @{ $self->SortCommands( $registered_commands[$$self]{ $c->[0] }{ $c->[1] } ) } );
		}

		if ( defined( $registered_commands[$$self]{ $c->[0] }{ 'GROUP' } ) )
		{
			push( @aliases , @{$self->SortCommands( $registered_commands[$$self]{ $c->[0] }{ 'GROUP' } ) } );
		}
	}
	elsif ( @{$c} == 3 )
	{
		if ( defined( $registered_commands[$$self]{ $c->[0] }{ $c->[1] }{ $c->[2] } ) )
		{
			push( @aliases , @{ $self->SortCommands( $registered_commands[$$self]{ $c->[0] }{ $c->[1] }{ $c->[2] } ) } );
		}

		if ( defined( $registered_commands[$$self]{ $c->[0] }{ $c->[1] }{ 'GROUP' } ) )
		{
			push( @aliases , @{ $self->SortCommands( $registered_commands[$$self]{ $c->[0] }{ $c->[1] }{ 'GROUP' } ) } );
		}
	}
	elsif ( @{$c} == 4 )
	{
		if ( defined( $registered_commands[$$self]{ $c->[0] }{ $c->[1] }{ $c->[2] }{ $c->[3] } ) )
		{
			push( @aliases , @{ $self->SortCommands( $registered_commands[$$self]{ $c->[0] }{ $c->[1] }{ $c->[2] }{ $c->[3] } ) } );
		}
		if ( defined( $registered_commands[$$self]{ $c->[0] }{ $c->[1] }{ $c->[2] }{ 'GROUP' } ) )
		{
			push( @aliases , @{ $self->SortCommands( $registered_commands[$$self]{ $c->[0] }{ $c->[1] }{ $c->[2] }{ 'GROUP' } ) } );
		}
	}

	$self->Verbose("ListCommands: Aliases dump",2,\@aliases);

	foreach my $command ( @aliases )
	{
		$cmds{ $command->[0] } = $command->[1];
	}

	$self->Verbose("ListCommands: cmds dump",2,\%cmds);

	if ( %cmds )
	{

		# always return something defined.
		$txt = '';
		$code = 200;
	}
	else
	{
		$txt .= "Commands not found";
		$code = 404;
#		%cmds = undef;
		$self->Verbose("ListCommands: Whoooops! \n",1,\@aliases);
	}

	$self->Verbose("ListCommand: cmds(".(scalar keys %cmds).") txt(".$txt.") \n",1);
	return(\%cmds, $txt, $code);
}

=item RegisterCommand

RegisterCommand is an internal object method used to Register
Agent::TCLI::Package::Command objects directly.

=cut

sub RegisterCommand {
    my ($self, $cmd, $package) = @_;
	$self->Verbose( "RegisterCommand: ".$cmd->name."  " );

	# Set a default package if not defined.
	$package = defined($package) ? $package."::".$cmd->name :
		'Control'."::".$cmd->name;

	if ( defined( $registered_commands[$$self]{'registered'}{ $package }) )
	{
		# We could die here, but then one would have to iterate over each failure
		# Though it might be nice to make failure more apparent. A MOTD perhaps?
		$self->Verbose( "RegisterCommand: ".$cmd->name." already registered! ",0 );
		$self->Verbose( "RegisterCommand: registered_commands dump  ",1,$self->registered_commands );
	}
	else
	{
		# need to figure out a way to do a reverse lookup on the name...
		$registered_commands[$$self]{'registered'}{ $package } = $cmd;
		$self->RegisterContexts($cmd);
	}

    return 1;
}

=item RegisterPackage

RegisterPackage is an internal object method used to register and entire
package of commands. It calls the Package's RawCommands method
to get the list of commands that need to be registered.

=cut

sub RegisterPackage {
	my ($self, $package) = @_;
	my ($commands, $txt);
	$self->Verbose( "RegisterPackage: $package " );
#	eval { require "$package" };
#	if ($@) {
#		$txt = "Bad package $package $@";
#		return $txt
#		};

	$commands = $package->commands();

    if ( ref($commands) eq 'ARRAY')
    {
    	foreach my $cmd (@{ $commands } )
    	{
        	if(ref $cmd eq 'HASH') {
            	$self->Register($cmd);
	    	} elsif ( ref($cmd) =~ /Agent::TCLI::Command/ ) {
				$self->RegisterCommand($cmd, $package);
            } else {
                $txt = "Parameter 'commands' contains illegal element";
            }
        }
    }
    elsif ( ref($commands) eq 'HASH' )
    {
    	foreach my $cmd ( values %{ $commands } )
    	{
        	if(ref $cmd eq 'HASH') {
            	$self->Register($cmd);
	    	} elsif ( ref($cmd) =~ /Agent::TCLI::Command/ ) {
				$self->RegisterCommand($cmd, $package);
            } else {
                $txt = "Parameter 'commands' contains illegal element";
            }
        }
    }
    else
    {
        $self->Verbose( "RegisterPackage: Bad package $package->dump(1) ",0 );
        $self->Verbose( "RegisterPackage: Bad package commands  ref(".ref($commands).")  dump",0,$commands );
        $txt = "Bad package $package";
    }
	return $txt;
}

=item _start

POE event to load up any initialization routines for commands.

=cut

sub _start {
    my ($kernel,  $self,  $session) =
      @_[KERNEL, OBJECT,   SESSION];

	if (!defined( $self->id ))
	{
		$self->Verbose("_start: OIO not done re-starting");
		$kernel->yield('_start');
		return;
	}

    $kernel->alias_set("$id[$$self]");

    $self->Verbose("_start: Starting commands start routines \n");

    foreach my $startcmd ( @{ $starts[$$self] } ) {
	    if ( ref($startcmd) eq 'HASH' )
	    {
	        if (defined ($startcmd->{'start'})) {
	            $self->Verbose("_start:\trunning ".$startcmd->{'name'}." 's start \n",2) ;
	            eval { $startcmd->{'start'}( kernel  => $kernel,
	                                         object  => $self,
	                                         session => $session,
	                                         ) }
	        }
	    }
	    elsif ( ref($startcmd) =~ /Agent::TCLI::Command/ )
	    {
            $self->Verbose("_start:\trunning ".$startcmd->name()." 's start \n",2) ;
	    	# TODO some error checking here maybe :)
	    	$startcmd->start( {	kernel  => $kernel,
	                           	object  => $self,
	                       		session => $session,
	    	} );
	    }

    }

	# Handlers are events to send the request to. The result will be returned
	# to AsYouWished.
	# The handler is the name of the event, and the command is the session that
	# will handle the event.
	# Often the handler name will not be the actual command name.

	# TODO, this isn't doing anything right now. Should it? Or are we doing it in the
	# _starts session creation....
    $self->Verbose("_start: Insert command handler states \n");

    foreach my $command ( @{ $handlers[$$self] } ) {
    	# if the command is not defined, the handler is assumed to be pre-loaded
        if ( ref($command->{'command'}) =~ /CODE/ ) {
            $self->Verbose("_start:\tregistering ".$command->{'name'}." 's handler $command->{'handler'} \n", 2 );
		    $kernel->state( $command->{'handler'} , $command->{'command'} );
        }
    }


#    unless ($heap->{no_std_tie}) {
#    	$self->Verbose "tie STDOUT and STDERR \n" if VERBOSE;
#        tie *STDOUT, __PACKAGE__."::Output", 'stdout', \&jabber_send_msg;
#        tie *STDERR, __PACKAGE__."::Output", 'stderr', \&jabber_send_msg;
#    }
#
#    if ($heap->{ties}) {
#        foreach (@{$heap->{ties}}) {
#         	$self->Verbose "tie $_  \n" if VERBOSE;
#            tie *$_, __PACKAGE__."::Output", $_, \&jabber_send_msg;
#        }
#    }

	if( $self->session )
	{
  		$self->set(\@start_time, time() );
		$self->Verbose( "_started: up at ".$self->start_time.
			" _start completed. \n\n");
  	}

} # End sub _start

=item stop

Poe state that is mostly just a placeholder.

=cut

sub _stop {
    my ($kernel, $self, $session) = @_[KERNEL, OBJECT, SESSION];
    $self->Verbose("Stopping ".$self->id );
    return ('_stop '.$self->id )
}

=item shutdown

POE event to forcibly shutdown the CLI control. It will call the stops for
all registered commnds that requested them. This probably is not necessary,
as their sessions will clean up after themselves.

=cut

sub _shutdown {
    my ($kernel, $self, $session) = @_[KERNEL, OBJECT, SESSION];
    foreach my $cmd ( @{ $stops[$$self] } ) {
        if (defined ($cmd->stop)) {
            $self->Verbose("\t running $cmd 's stop \n" , 2 );
            eval { $cmd->stop( $kernel, $self, $session ) }
        }
    }
	$kernel->alarm_remove_all();

    $kernel->alias_remove( $id[$$self] );
}

=item ControlAddState

POE Event handler that allows new state registrations.

=cut

sub ControlAddState {
    my ( $kernel,  $self, $command, $coderef, $method ) =
      @_[ KERNEL, OBJECT,     ARG0,     ARG1,    ARG2 ];
    $kernel->state( $command, $coderef, $method );
}

=item ChangeContext

Poe state that is used the handle all context changes. If a Command needs to
change the context, this is how to do it. The only argument
is a string instructing how to change the context.

'/' changes to root context.
'..' goes back one context
<string> adds <string> to the current context.

No verification is done to see that a reasonable context results from this.

Usually there is no need for a command to directly access change context,
as the Command::Base establish_context state will be able to handle most needs.

=cut

sub ChangeContext {
	my ($kernel,  $self, $request, $context) =
	  @_[KERNEL, OBJECT,     ARG0,     ARG1];
    $self->Verbose("ChangeContext: context($context)  \n" , 2 );

	# There is no checking to see if this is a valid context to be in.
	if ( ref($context) eq 'ARRAY' )
	{
		$self->context( $context );
	}
	else
	{
	    # In case someone forgets and gives us a bad context, set to root.
	    $context = 'ROOT' if ( !defined ($context) or $context !~ /\S+/ );

	    # Store the new context
		if ($context eq '..')
		{
		    $self->pop_context;
		}
		elsif ( $context eq '/' )
		{
		    $self->context(['ROOT']);
		}
		else
		{
		    $self->push_context( $context ) ;
		}
	}

    # TODO make sure each transport has a ChangeContext
    # registered as a context shift handler....
    $self->Verbose("ChangeContext: Context now (".$self->print_context.") for request \n" , 4,$request );

	$kernel->call( $self->owner->session->ID => 'SendChangeContext' => $self );

	$request->Respond($kernel, "Context now: ".$self->print_context );
}

=item control_presence

This is very transport specific, and I'm not sure how to handle presence quite yet.

=cut

sub control_presence {
	my ($kernel,  $self,  $presence) =
	  @_[KERNEL, OBJECT,       ARG0 ];

    $self->Verbose("\tCP\tPresence:  ".$presence." \n", 2 );

}

=item Execute

POE event Execute is the main event handler for incoming reuqests.
Transports should send command requests to Execute. The can be either
plain text as entered by the user or request objects.

Usage:

	$kernel->post( 'Control' => 'Execute' => $input );

=cut

sub Execute {
    my ($kernel,  $self, $input) =
      @_[KERNEL, OBJECT,   ARG0];
    $self->Verbose( "Execute: Input($input) ",2);
	my (@args,$request);

	# is input a request object or plaintext?
	if (ref($input) =~ /Request/)
	{
		$request = $input;
		$input = $request->input;
	    $self->Verbose( "Execute: Request ".$request->dump(1),4);
	    $self->Verbose( "Execute: input from Request ($input)",2,\$input);

	 	# Here we need to extract the command for FindCommand
		# Odds are the request doesn't have args or command populated
		# if it was built outside of the Control.
		if ( defined($request->args) )
		# Hmm, someone thinks they're smarter than the Control at
		# parsing. OK, we'll take that. Later we'll use the real args.
		{
		 	@args = reverse( @{$request->command} );
		}

		# add self to sender/postback stack so that we can put ourself
		# into PostResponse to Transport to handle many contrls per transport
		# Or should I just stuff that into the request at the Transport
		# Well, what if there isn't a request yet at the transport?
		# Either the request exists or it will come from the control....
		# Or just make the stateful transports create a request...
		# I think that is more elegant.
		# Scratch all this.
	}

    $self->Verbose( "Execute: args",2,\@args);

	# Now get args from input.
	if ( ! @args )
	{
		# TODO Still need a better parser.
		# Parsewords chokes on single singlequotes.
		$input =~ s/'//;
		# parsewords also parses whitespace at the beginning poorly.
		$input =~ s/^\s*//;
		# Parsewords doesn't handle trailing backslashes well.
		$input =~ s/\\$//;
	    @args = shellwords($input);
	}

	# substitute for help
    $args[0] = 'help' if ($args[0] eq '?');

#	# The command is broken down into a context, a command, and args.
#	# The context helps find the command to execute and usually
#	# remains the same between transactions unless changed by the user.
#	# Context may be up to five layers deep. A single command may be
#	# usable in more than one context, or even in all.
#
#	# The command is sent as the first arg in @args.
#
#	# Each command gets the following to execute:
#	# $postback -> to send the response
#	# \@args -> typically the user input in an array
#	# $input -> the original user input
#	# $thread -> the thread object for the user's session
#	#	The current context is stored in the $thread as an array but is
#	# retrievable as a string as well.
#
#	# Some commands merely establish context. Such as 'enable' in a Cisco
#	# CLI. Though enable may require additional args. A default method/session
#	# of the Agent::TCLI::Package::Base class called establish_context can handle
#	# the simple case of setting context and confirming for the user.
#
#	# $args[0] will always be the command word to execute, but may have
#	# not been the first word entered if the command is nested deep in a
#	# context. If a command needs to determine exactly how it was called
#	# then it needs to reparse $input.

	my ($cmd, $context, $txt, $code) = $self->FindCommand(\@args);

	unless ($code == 404)
	{

	    $self->Verbose("Execute: Executing cmd(".$cmd->name.
	    	") for ".$id[$$self]." \n");

		# Now actually execute the command
	    if ( ref($request) =~ /Request/ )
	    {
			if ( !defined($request->args) || $request->depth_args == 0 )
			{
				$request->args( \@args );
				$request->command( $context );
			    $self->Verbose( "Execute: Request post FindCommand".$request->dump(1),3);
			}

	    	# The response may bypass the Control's AsYouWished, and go
	    	# directly back to the Transport if that is what is $request(ed)
	    	if ( $cmd->call_style  eq 'sub')
		    {
				# Subs can't handle request objects.
				my (@rargs, $rinput);

				# subs want the command in the @rargs
				push( @rargs, $request->command->[0], $request->args );

				# Make sure there is input, just in case....
				$rinput = defined($request->input) ? $request->input :
					join(' ',$request->command->[0],$request->args);

				# do it
		    	($txt, $code) = $self->DoSub($cmd, \@rargs, $rinput );
		    	$request->Respond( $kernel, $txt, $code);
		    	return;
			}
			elsif ( $cmd->call_style  eq 'state')
			{
				$self->Verbose("Execute: Executing state ".$cmd->handler." \n");
				$kernel->yield( $cmd->handler => $request );
				return;
			}
			elsif ( $cmd->call_style  eq 'session')
			{
				$self->Verbose("Execute: Executing session ".$cmd->command.
					"->".$cmd->handler." \n");
				$kernel->post($cmd->command => $cmd->handler =>
					$request );
				return;
			}
	    }
		else
	    {
	    	if ( $cmd->call_style  eq 'sub')
		    {
		        ($txt, $code) = $self->DoSub($cmd, \@args, $input );
			}
			else
			{
				my $request = Agent::TCLI::Request->new(
					'args'		=> \@args,
					'command'	=> $context,
					'sender'	=> $self,
					'postback'	=> 'AsYouWished',
					'input'		=> $input,

					'verbose'		=> $self->verbose,
					'do_verbose'	=> $self->do_verbose,

				);
				if ( $cmd->call_style  eq 'state')
				{
					$self->Verbose("Execute: Executing state ".$cmd->handler." \n");
					$kernel->yield( $cmd->handler => $request );
					return;
				}
				elsif ( $cmd->call_style  eq 'session')
				{
					$self->Verbose("Execute: Executing session ".$cmd->command.
						"->".$cmd->handler." \n");
					$kernel->post($cmd->command => $cmd->handler =>
						$request );
					return;
				}
			}
	    }
	}

    unless ( defined($txt) )
    {
    	$txt = 'Uh oh, Execute bombed';
    	$code = 400;
    }
    $self->Verbose("Execute: Got ".$txt." from in ".$self->id." ", 3 );
    if ( ref($request) =~ /Request/ )
    {
		$request->Respond($kernel, $txt, $code );
    }
    else
    {
		my $response = Agent::TCLI::Response->new(
				'body'		=> $txt,
				'code'		=> $code,
		);
	    $kernel->yield('AsYouWished' => $response ) ;
    }

} #end sub Execute

=item DoSub

This internal object method performs the actual execution of commands
that are only small subs.

=cut

sub DoSub {
	my ($self, $cmd, $args, $input) = @_;
	$self->Verbose("DoSub: sub ".$cmd->name." \n");

	my $txt = eval {
    	&{$cmd->command}( $args, $input );
	};
	if($@)
	{
		$self->Verbose("DoSub: Error (".$@.") \n" );
		return ("RUN ERROR: $@", 400);
	}
	else
	{
		$self->Verbose("DoSub: sub returned (".$txt.") \n",4 );
	}
	return ($txt, 200);
}

=item AsYouWished

This POE state takes a text reply to a transaction and returns it to the proper
transport for sending to the user. This has been somewhat deprecated by
the Respond method in request objects.

Commands that are executed as sessions may use this as a return and
should not try to interact with the transports
directly. It is called by run for legacy command calls.

It prefers a response object, but will wrap plain text into a response object
for consistent transport handling.

=cut

sub AsYouWished {
	my ($kernel, $sender,  $self, $response) =
	  @_[KERNEL,  SENDER, OBJECT,  ARG0 ];

	# at this point, we should be getting a response object,
	# but let's not complain.
	if ( ref($response) =~ /Response/ )
	{
		$self->Verbose( "AsYouWished: Got ".$response->dump(1)." in ".$self->id." \n");
		# um I was going to do something here.
	}
	else   # Need to build response
	{
		$self->Verbose( "AsYouWished: Got '".$response."' in ".$self->id." \n");
		my $response = Agent::TCLI::Response->new(
		# Don't have request, sending just plain response, hopefully the
		# transport knows where it came from based on the sender.
		# We really shouldn't be here anyway.
			'body'		=> $response,
			'code'		=> 200,
		);
	}

	# Is this what I want to do? Or should I Respond?
	# The Control always acts directly as the interface between Transport
	# and control is strictly defined. If we're here, there probably isn't a
	# request object to respond to.
	$self->Verbose( "AsYouWished: self dump \n",5,$self );
	$kernel->post( $self->owner->session->ID => 'PostResponse' => $response, $self );

} #end sub control_AsYouWished

#sub control_err {
#	my ($err, $msg) = @_;
#  croak("ERROR: $err -> $msg  \n");
#}

=item general

A POE event to handle some general commands such as context and status.
It expects a request object parameter.

=cut

sub general {
    my ($kernel,  $self, $sender, $request,) =
      @_[KERNEL, OBJECT,  SENDER,     ARG0,];
	$self->Verbose("general: context(".$self->print_context.")");

	my $command = $request->command->[0];
	$self->Verbose("general: command(".$command.") args[".
		$request->print_args."] input(".$request->input.")", 3);

	my $txt;
	my $time = localtime($start_time[$$self]);

	if ( $command eq 'context')
	{
	    $txt = "Context: ".$self->print_context;
	}
	elsif ( $command eq 'echo' )
	{
    	$txt = "I heard '".$request->input."' in context ".
    		$self->print_context." from ".$user[$$self]->get_name();
	}
	elsif ($command =~ /hi|hello/i)
	{
    	$txt = $command." ".$user[$$self]->get_name().". Tell me what you'd like to do or ask for 'help'. ";
	}
	elsif ($command eq 'status')
	{
		$txt .= "This is a ".__PACKAGE__." v".$VERSION."\n";
		$txt .= "running inside ".$0.".\n";  # with procecss id ".getppid()."\n";
		$txt .= "My IP address is ".$self->local_address.".\n" if defined($self->local_address);
		$txt .= "This console was spawned at ".$time.".\n";
		foreach my $cmdpkg ( @{ $packages[$$self] } )
		{
			my $subtxt = "$cmdpkg";
			$subtxt =~ s/=.*//;
			$txt .= "\tPackage ".$subtxt." is loaded. \n";
		}
		$txt .= "You are ".$user[$$self]->get_name()." and you have "
			.$self->auth()." authorization \n ";
		$txt .= "\n";
	}
	elsif ( $command eq 'Verbose' )
	{
		if ( $request->args->[0])
		{
			$self->verbose( $request->args->[0] );
   		 	$txt = "Verbose now ".$self->verbose." in context ".
    			$self->print_context;
		}
		else
		{
   		 	$txt = "Verbose: ".$self->verbose;
		}
	}
	elsif ( $command eq 'debug_request' )
	{
    	$txt = "Request dump: ".$request->dump(1);
	}
	else
	{
		$txt = "Uh oh, this was not supposed to happen. $command got lost."
	}

	$self->Verbose("general: txt($txt)",3);

	$request->Respond($kernel, $txt);

} #end sub general

=item net

A POE event to execute the net commands. Takes a request object as an ARG0.
The only command it handles currently is I<ip>. This will respond with the
local_address if defined.

=cut

sub net {
    my ($kernel,  $self, $request, ) =
      @_[KERNEL, OBJECT,     ARG0, ];

	my $command = $request->command->[0];
	my ($txt, $code);

    $self->Verbose("net: command($command)");

	if ( $command eq 'ip' )
	{
		if (defined($self->local_address))
		{
			$txt = $self->local_address;
			$code = 200;
		}
		else
		{
			$txt = 'Local ip address is undefined.' ;
			$code = 400;
		}
	}

    $request->Respond( $kernel, $txt, $code );
    return ();
} #end sub exit

=item help

A POE event to execute the help command. Takes a request object as an ARG0.
Responds with the properly formatted help output.

=cut

sub help {
    my ($kernel,  $self, $sender, $request,) =
      @_[KERNEL, OBJECT,  SENDER,     ARG0,];
	$self->Verbose("help: \t"." with context(".$self->print_context.")");
	$self->Verbose("help: command(".$request->command->[0].") args[".
		$request->print_args."] input(".$request->input.")", 3);
	my $command = $request->command->[0];

	my (@help, $cmd, $cmds, $context, $txt, $code);

    # No specific request, print list of commands with usage.
    if ( not defined($request->args->[0]) )
    {
    	($cmds, $txt, $code) = $self->ListCommands();
 		if ( $code == 200 )
 		{
	    	$txt = "The following commands are available in this context. \n";
	        foreach $cmd ( sort keys %{$cmds} )
	        {
	        	$self->Verbose("help: cmd($cmd) ");
	        	# Need to eliminate aliases by checking something.....
	            $txt .= "\t".$cmd." - ".$cmds->{$cmd}->help." \n"
	            	if ($cmds->{$cmd}->name =~ /$cmd/ ||
	            		$cmds->{$cmd}->topic !~ /general/
	            	);
	        }
 		}
    	($cmds, , ) = $self->ListCommands(['UNIVERSAL']);
 		if ( $code == 200 )
 		{
	    	$txt .= "\nThe following global commands are available. \n";
	        foreach $cmd ( sort keys %{$cmds} )
	        {
	            $txt .= " ".$cmd." " unless ($cmds->{$cmd}->topic =~ /debug|admin/);
	        }
 		}
 		# Otherwise txt has error from first ListCommands
		$request->Respond($kernel, $txt, $code );
		return;
    }
	# Just the globals please
    elsif( $request->args->[0] =~ /global/i )
    {
    	($cmds, $txt, $code ) = $self->ListCommands(['UNIVERSAL']);
 		if ( $code == 200 )
 		{
	    	$txt .= "\nThe following global commands are available. \n";
	        foreach $cmd ( sort keys %{$cmds} )
	        {
	            $txt .= "\t".$cmd." - ".$cmds->{$cmd}->help." \n";
	        }
 		}
 		# Otherwise txt has error from first ListCommands
		$request->Respond($kernel, $txt, $code );
		return;
    }
	# perhaps we want to ignore the current context
    elsif ( $request->args->[0] eq '/' )
    {
    	@help = @{$request->args};
    }
    # finally, just help
    elsif ( $request->depth_args >= 1 )
    {
	    @help = ( @{$self->context}, @{$request->args} );
	    unshift(@help,'/') if ($help[0] ne '/');
    }

	($cmd, $context, $txt, $code) = $self->FindCommand(\@help);
	# FindCommand eats @help (as args) and we need what it found in context
	@help = reverse(@{$context});
	my $on = join(' ',@help);

	if (defined($cmd) && defined($cmd->help) )
	{
    	$txt = "Help for command '".$on."'  Use 'manual ".$on."' for more info.\n";
        $txt .= "\tUsage: ".$cmd->usage."\n";
	    $txt .= $cmd->help."\n";
	    if (defined( $cmd->parameters ) )
	    {
		    $txt .= "Parameters \n";
	      	foreach my $parameter ( sort keys %{$ cmd->parameters } )
	       	{
	      		$txt .= "\t".$cmd->parameters->{ $parameter }->name." - ";
	      		$txt .= $cmd->parameters->{ $parameter }->help;
	       	}
	    }

	}
	elsif (defined($cmd) )
	{
		$txt = "Darn! The lazy programmer didn't supply a manual or help!"
	}
	# Otherwise txt has error from FindCommand

	$request->Respond($kernel, $txt, $code );
} #end sub help

=item manual

A POE event to execute the manual command. Takes a request object as an ARG0.
Responds with the properl formatted manual output.

=cut

sub manual {
    my ($kernel,  $self, $sender, $request,) =
      @_[KERNEL, OBJECT,  SENDER,     ARG0,];
	$self->Verbose("manual: \t"." with context(".$self->print_context.")");
	$self->Verbose("manual: command(".$request->command->[0].") args[".
		$request->print_args."] input(".$request->input.")", 3);
	my $command = $request->command->[0];

	my (@manual, $cmd, $cmds, $context, $txt, $code);

    if ( $request->args->[0] eq '/' )
    {
    	@manual = @{$request->args};
    }
    elsif ( $request->depth_args >= 1 )
    {
	    @manual = ( @{$self->context}, @{$request->args} );
	    unshift(@manual,'/') if ($manual[0] ne '/');
    }
    else
    {
        $txt = "Manual requires an argument";
        $code = 400;
		$request->Respond($kernel, $txt, $code );
		return;
    }

 	($cmd, $context, $txt, $code) = $self->FindCommand(\@manual);
	# FindCommand eats @manual (as args) and we need what it found in context
	@manual = reverse(@{$context});

	if (defined($cmd) && defined($cmd->manual) )
	{
    	$txt = "Manual for command '".join(' ',@manual)."' \n";
        $txt .= "\tUsage: ".$cmd->usage."\n";
        $txt .= $cmd->manual."\n";
        # TODO Parameter print method to format better output.
	}
	elsif (defined($cmd) && defined($cmd->help ) )
	{
        $txt = "No manual defined. Here is help for command '".
          	join(' ',@manual)."' \n";
        $txt .= "\tUsage: ".$cmd->usage."\n";
        $txt .= $cmd->help."\n";

	}
	elsif (defined($cmd) )
	{
		$txt = "Darn! The lazy programmer didn't supply a manual or help!"
	}

    if (defined( $cmd->parameters ) )
    {
     	$txt .= "Parameters:\n";
       	foreach my $parameter ( sort keys %{$ cmd->parameters } )
       	{
       		$txt .= "\n".$cmd->parameters->{ $parameter }->name." \n";
       		$txt .= $cmd->parameters->{ $parameter }->manual;
       	}
    }
    elsif ( $cmd->handler eq 'establish_context')
    {
    	my ($subcmds, $subtxt, $subcode) = $self->ListCommands(\@manual);
 		if ( $subcode == 200 )
 		{
	    	$txt .= "The following sub commands are available: \n";
	        foreach my $subcmd ( sort keys %{$subcmds} )
	        {
	        	$self->Verbose("manual: subcmd($subcmd) ");
	        	# Need to eliminate aliases by checking something.....
	            $txt .= "\t".$subcmd." - ".$subcmds->{$subcmd}->help." \n"
	            	if ($subcmds->{$subcmd}->name =~ /$cmd/ ||
	            		$subcmds->{$subcmd}->topic !~ /general/
	            	);
	        }
 		}

    }

	# Otherwise txt has error from FindCommand
#    }
#    elsif ( $request->depth_args == 1 )
#    {
#    	my $on = $request->args->[0];
#	    my @manual = ( '/', @{$self->context}, $on );
# 		($cmd, $context, $txt, $code) = $self->FindCommand(\@manual);
#
#		if (defined($cmd) && defined($cmd->manual) )
#		{
#            $txt = "Manual for command '".$on."' \n";
#            $txt .= "\tUsage: ".$cmd->usage."\n";
#            $txt .= $cmd->manual."\n";
#            # TODO Parameter print method to format better output.
#            if (defined( $cmd->parameters ) )
#            {
#	            $txt .= "Parameters:\n";
#            	foreach my $parameter ( sort keys %{$ cmd->parameters } )
#            	{
#            		$txt .= "\n".$cmd->parameters->{ $parameter }->name." \n";
#            		$txt .= $cmd->parameters->{ $parameter }->manual;
#            	}
#            }
#		}
#		elsif (defined($cmd) && defined($cmd->help ) )
#		{
#            $txt = "No manual defined. Here is help for command '".$on."' \n";
#            $txt .= "\tUsage: ".$cmd->usage."\n";
#            $txt .= $cmd->help."\n";
#            if (defined( $cmd->parameters ) )
#            {
#	            $txt .= "Parameters \n";
#            	foreach my $parameter ( sort keys %{$ cmd->parameters } )
#            	{
#            		$txt .= "\t".$cmd->parameters->{ $parameter }->name." - ";
#            		$txt .= $cmd->parameters->{ $parameter }->help;
#            	}
#            }
#
#		}
#		elsif (defined($cmd) )
#		{
#			$txt = "Darn! The lazy programmer didn't supply a manual or help!"
#		}
#
#		# Otherwise txt has error from FindCommand
#    }
	$request->Respond($kernel, $txt, $code );

} #end sub manual

=item exit

A POE event to handle context shift commands exit and /.
It expects a request object parameter.

=cut

sub exit {
    my ($kernel,  $self, $request, ) =
      @_[KERNEL, OBJECT,     ARG0, ];
#	$self->Verbose("exit: command($args->[0]) args[".scalar($args)
#		."] input($input)", 4);
	my $command = $request->command->[0];

    $self->Verbose("exit: command($command)");
    my $context;
    # we're set up to handle '/' as well as exit and '..'
    if ($command eq '/' || $command eq 'root' )
    {
    	$context = '/';
    }
    else
    {
    	# Used to do a lot more here, but pushed it off to change context.
    	$context = '..';
    }
#    $request->Respond( $kernel, "exiting: context now ".$context, 200 );
    $kernel->yield( 'ChangeContext', $request, $context );
    return ();
} #end sub exit

=item dumpcmd

A POE event to handle some debugging in band.
It expects a request object parameter.

=cut

sub dumpcmd {
	my ($kernel,  $self,  $request) =
	  @_[KERNEL, OBJECT,      ARG0];

	my $command = $request->command->[0];

	my $txt;

	# dump them all if no args
 	if ( $request->ArgsDepth == 0 )
  	{
		foreach my $cmd ( keys %{ $registered_commands[$$self] } )
		{
			$txt .= $registered_commands[$$self]{$cmd}->dump(1);
		}
	}
	elsif ( $request->ArgsDepth > 0 )
	{
		foreach my $cmd ( @{$request->args} )
		{
			$txt .= $registered_commands[$$self]{$cmd}->dump(1);
		}
	}

	$request->Respond( $kernel,  $txt );
} #end sub dumpcmd

#sub listcmd {
#	my ($kernel,  $self,  $request) =
#	  @_[KERNEL, OBJECT,      ARG0];
#
#	my $command = $request->command->[0];
#
#	my $txt;
#	# TODO this is broken with new commands hash.
#	if ( $request->depth_args == 0
#	{     # dump them all
#		foreach my $context ( $registered_commands[$$self] )
#		{
#  			$txt .= "\nCommands in context ".$context." \n\t";
#  			foreach my $command ( %{ $registered_commands[$$self]{ $context } } )
#  			{
#				$txt .= $registered_commands[$$self]{ $context }{ $command }{'name'}.", ";
#  			} #end foreach command
#		} #end foreach context
#	}
#	else
#	{
#  		# just dump some in a context
#
#		# tHIS SHOULD GRAB AN ARRAY
#  		my $context = $request->depth_args > 0 ? $request->args->[0] : $thread[$$self]->context;
#
#  		# if/eslif on size of array.
#  		# loop over hash1.hash2.hash3.keys getting '.'{'name'}
#  		# loop over wildcards too
#
#		foreach my $cmd ( %{ $registered_commands[$$self]{ $context } } )
#		{
#			$txt .= $registered_commands[$$self]{ $context }{ $cmd }{'name'}.", ";
#		}
#	}
#	$txt =~ s/,\s$//;
#	$request->Respond( $kernel,  $txt );
#} #end sub listcmd


#=item establish_context
#
#This POE event handler is the primary way to set context with a command.
#Just about any command that has subcommands will use this method as it's handler.
#An exception would be a command that sets an single handler to process all
#subcoammnds/args using the 'A*' context. See the Eliza package for an example of
#how to establish that type of context.
#
#=cut
#
#sub establish_context {
#    my ($kernel,  $self, $sender, $request, ) =
#      @_[KERNEL, OBJECT,  SENDER,     ARG0, ];
#	$self->Verbose("establish_context: ".$self->name." for request(".
#		$request->id().")");
#
#	my $txt;
#	# if we have args, then the command is invalid
#	if ( $request->depth_args > 0 )
#	{
#		$txt .= "Invalid input: ".$request->input;
#		$self->Verbose("establish_context: Invalid input (".$request->input.")"  );
#		$request->Respond($kernel, $txt, 404) if $txt;
#		return;
#	}
#
#	# we don't know how deep we're in already. So we'll force a full context shift.
#	# by sending the entire command array back, which is revesred.
#	my @context = reverse (@{$request->command});
#
#	# We don't actualy set the controls context, but let change context do that.
#	# It will also inform the user of change.
#
#   	# Post context back to sender (Control)
#   	$kernel->call( $sender => 'ChangeContext' => $request, \@context );
#	$self->Verbose("establish_context: setting context to "
#			.join(' ',@context)." ",2);
#
#}
#
#=item show
#
#This POE event handler i will accept an argument for the setting to show.
#It will also take an argument of all or * and show all settings.
#
#The parameter must be defined in the command entry's parameters or it will
#not be shown. There must also be a OIO Field defined with the same name.
#One may write their own show method if this is not sufficient.
#
#=cut
#
#sub show {
#    my ($kernel,  $self, $sender, $request, ) =
#      @_[KERNEL, OBJECT,  SENDER,     ARG0, ];
#	$self->Verbose("show: request(".$request->id.") ",2);
#
#	my ($txt, $code, $what, $var);
#	# calling with show as a command, that is the handler for show is show.
#	if ( $request->command->[0] eq 'show' ) 	# cmd1 show arg
#												# cmd1 attacks show <arg>
#	{
#		$what = $request->args->[0];
#	}
#
#	$self->Verbose("show: what(".$what.") request->args",1,$request->args);
#
#	ATTR: foreach my $attr ( keys %{ $self->commands->{'show'}->parameters } )
#	{
#		if ( $what eq $attr || $what =~ qr(^(\*|all)$))
#		{
#			if ( $self->can( $attr ) && defined( $self->$attr) )
#			{
#				my $ref = ref($self->$attr);
#				my $show = ( defined($self->parameters ) &&
#					defined($self->parameters->{ $attr } ) &&
#					defined($self->parameters->{ $attr }->show_method ) )
#					? $self->parameters->{ $attr }->show_method
#					: '';
#				$self->Verbose("show attr($attr) ref($ref) show($show)",1);
#				# simple scalar
#				if ( not $ref)
#				{
#					$txt .= "$attr: ".$self->$attr." \n";
#					$code = 200;
#				}
#				# is it an object and show_method is defined?.
#				elsif ( $ref =~ qr(::) && blessed( $self->$attr )
#					&& $show )
#				{
#					$txt .= "$attr: ".$self->$attr->$show."\n";
#					$code = 200;
#				}
#				# is it an object with dump? Probably OIO.
#				elsif ( $ref =~ qr(::) && blessed($self->$attr)
#					&& $self->$attr->can( 'dump') )
#				{
#					$var = $self->$attr->dump(0);
#					$txt .= Dump($var)."\n";
#					$code = 200;
#				}
#				elsif ( $ref =~ qr(HASH) )
#				{
#					foreach my $key ( sort keys %{$self->$attr} )
#					{
#						my $subref = ref($self->$attr->{ $key }   );
#						$self->Verbose("show key($key) subref($subref)",0);
#						# simple scalar
#						if ( not $subref )
#						{
#							$txt .= "$attr ->{ $key }: ".$self->$attr->{$key}." \n";
#							$code = 200;
#						}
#						# is it an object and show_method is defined?.
#						elsif ( $subref =~ qr(::) &&
#							blessed($self->$attr->{ $key }) &&
#							defined($show) )
#						{
#							$txt .= "$attr: ".$self->$attr->{$key}->$show."\n";
#							$code = 200;
#						}
#						# is it an object with dump? Probably OIO.
#						elsif ( $subref =~ qr(::) &&
#							blessed($self->$attr->{ $key }) &&
#							$self->$attr->{ $key }->can( 'dump') )
#						{
#							$var = $self->$attr->{$key}->dump(0);
#							$txt .= Dump($var)."\n";
#							$code = 200;
#						}
#						# some other object, array or hash
#						else
#						{
#							$var = $self->$attr->{$key};
#							$txt .= Dump($var)."\n";
#							$code = 200;
#						}
#					}
#				}
#				elsif ( $ref =~ qr(ARRAY) )
#				{
#					my $i = 0;
#					foreach my $val ( @{$self->$attr} )
#					{
#						my $subref = ref( $val );
#						# simple scalar
#						if ( not $subref )
#						{
#							$txt .= "$attr ->[ $i ]: ".$val." \n";
#							$code = 200;
#						}
#						# is it an object and show_method is defined?.
#						elsif ( $subref =~ qr(::) &&
#							blessed($val) &&
#							defined($show) )
#						{
#							$txt .= "$attr: ".$val->$show."\n";
#							$code = 200;
#						}
#						# is it an object with dump? Probably OIO.
#						elsif ( $subref =~ qr(::) &&
#							blessed($val) &&
#							$val->can( 'dump') )
#						{
#							$var = $val->dump(0);
#							$txt .= Dump($var)."\n";
#							$code = 200;
#						}
#						# some other object, array or hash
#						else
#						{
#							$txt .= Dump($val)."\n";
#							$code = 200;
#						}
#					}
#				}
#				# some other object
#				else
#				{
#					$var = $self->$attr;
#					$txt .= Dump($var)."\n";
#					$code = 200;
#				}
#			}
#			elsif ( $self->can( $attr )  )
#			{
#		  		$txt = $what.": #!undefined";
#				$code = 200;
#			}
#			else # should get here, but might if parameter error.
#		  	{
#  				$txt = $what.": #!ERROR does not exist";
#  				$code = 404;
#  			}
#		}
#	}
#
#	# if we didn't find anything at all, then a 404 is returned
#  	if (!defined($txt) || $txt eq '' )
#  	{
#  		$txt = $what.": #!ERROR not found";
#  		$code = 404;
#  	}
#
#	$request->Respond($kernel, $txt, $code);
#}
#
#=item settings
#
#This POE event handler executes the set commands.
#
#=cut
#
#sub settings {  # Can't call it set
#    my ($kernel,  $self, $sender, $request, ) =
#      @_[KERNEL, OBJECT,  SENDER,     ARG0, ];
#
#	my $txt = '';
#	my ($param, $code);
#	my $command = $request->command->[0];
#	# called directly because $command may be an alias and not the real name
#	my $cmd = $self->commands->{'set'};
#
#	# TODO a way to unset/restore defaults....
#
#	# break down and validate args
#	return unless ($param = $cmd->Validate($kernel, $request) );
#
#	$self->Verbose("set: param dump",1,$param);
#
#	# Get meta data
#	my $meth = $self->meta->get_methods();
#
#	foreach my $attr ( keys %{$param} )
#	{
#		# param will have all fields defined, gotta skip the empty ones.
#		# Can't use ne due to NetAddr::IP bug
#		next unless (defined($param->{$attr})
##			&& !($param->{$attr} eq '')  # diabled, since we should be OK now.
#			);
#
#		$self->Verbose("settings: setting attr($attr) => ".
#			$param->{$attr}." ");
#
#		# is there a field type object for this attr?
#		if ( ref($param->{$attr}) eq '' &&
#			exists( $meth->{$attr} ) &&
#			exists( $meth->{$attr}{'type'} ) &&
#			$meth->{$attr}{'type'} =~ /::/ )
#		{
#			my $class = $meth->{$attr}{'type'};
#			$self->Verbose("set: class($class) param($param) attr($attr) ");
#			my $obj;
#			eval {
#				no strict 'refs';
#				$obj = $class->new($param->{$attr});
#			};
#			# If it went bad, error and return nothing.
#			if( $@ )
#			{
#				$@ =~ qr(Usage:\s(.*)$)m ;
#				$txt = $1;
#				$self->Verbose('set: new '.$class.' got ('.$txt.') ');
#				$request->Respond($kernel,  "Invalid: $attr !", 400);
#				return;
#			}
#			eval { $self->$attr($obj) };
#			if( $@ )
#			{
#				$@ =~ qr(Usage:\s(.*)$)m ;
#				$txt = $1;
#				$self->Verbose('set: new '.$class.' got ('.$txt.') ');
#				$request->Respond($kernel,  "Invalid: $attr !", 400);
#				return;
#			}
#			$txt .= "Set ".$attr." to ".$param->{$attr}." \n";
#			$code = 200;
#
#		}
#		else
#		{
#			eval { $self->$attr( $param->{$attr} ) };
#			if( $@ )
#			{
#				$@ =~ qr(Usage:\s(.*)$)m ;
#				$txt = $1;
#				$self->Verbose('set: $self->'.$attr.'( '.$param.'->{ '.
#					$attr.' } got ( '.$txt.') ');
#				$request->Respond($kernel,  "Invalid: $attr !", 400);
#				return;
#			}
#			$txt .= "Set ".$attr." to ".$param->{$attr}." \n";
#			$code = 200;
#		}
#	}
#
#  	if (!defined($txt) || $txt eq '' )
#  	{
#  		$txt = "Invalid: ".join(', ',keys %{$param} );
#  		$code = 404;
#  	}
#
#	$request->Respond($kernel, $txt, $code);
#}

=item print_context

An object method to get the current context in string form. It has no parameters.

=cut

sub print_context {
	my $self = shift;
	return ( join(' ', @{$context[$$self]} ) );
} # End sub print_context

=item push_context

An private object method to push onto the current context. It has no parameters.

=cut

sub push_context # :Restricted   How can I test with Restricted or Private?
{
	my ($self, $context) = @_;
	if ( $self->print_context eq 'ROOT' && $context ne '/' )
	{
		$self->context( [$context] );
		return (1);
	}
	elsif ( $context eq '/' )
	{
		# TODO create error instead of overwrite existing context.
		$self->context( ['ROOT'] );
		# Root is a null context
		return (0);
	}
	else
	{
		return( push( @{$context[$$self]} , $context ) );
	}

}

=item pop_context

An private object method to pop from the current context. It has no parameters.

=cut

sub pop_context # :Restricted
{
	my $self = shift;
	my $context = pop( @{$context[$$self]} );
	# context should never be empty. Make root if empty.
	if ( scalar( @{$context[$$self]} ) == 0 )
	{
		$self->context( ['ROOT'] );
	}
	return ($context);
}

=item depth_context

An object method to return the context depth. It has no parameters.
If the context is root ('ROOT') context depth wil return 0 even
though context [0] is populated with 'ROOT'.

=cut

sub depth_context {
	my $self = shift;
	my $depth;
	if ( $self->context->[0] eq 'ROOT' )
	{
		$depth = 0;
	}
	else
	{
		$depth = scalar( @{ $context[$$self] } );
	}
	return ( $depth );
}

=item _default

A POE event handler to handle events gone astray. Only does something
when verbose is turned on.

=cut

sub _default {
  my ($kernel,  $self, ) =
    @_[KERNEL, OBJECT, ];
	my $oops = "\n\n\n".
	"\t  OOOO      OOOO    PPPPPP    SSSSSS    ##  \n".
	"\t OO  OO    OO  OO   PP   PP  SS         ##  \n".
	"\tOO    OO  OO    OO  PP   PP  SS         ##  \n".
	"\tOO    OO  OO    OO  PPPPPP    SSSSSS    ##  \n".
	"\tOO    OO  OO    OO  PP             SS   ##  \n".
	"\t OO  OO    OO  OO   PP             SS       \n".
	"\t  OOOO      OOOO    PP        SSSSSS    ##  \n";
	$self->Verbose($oops);
	$self->Verbose("\n\nDefault caught an unhandled $_[ARG0] event.\n");
	$self->Verbose("The $_[ARG0] event was given these parameters:");
	$self->Verbose("ARG1 dumped",1,$_[ARG1]) if defined($_[ARG1]);
	$self->Verbose("ARG2 dumped",1,$_[ARG2]) if defined($_[ARG2]);
  return(0);
}

=item _default_commands

A private object method that has all the default commands.
The ones we just can't live without. Well, maybe not all the ones we can't
live without, but all the ones that have actually be written so far.

=cut

sub _default_commands :Private {
	my $self = shift;
	my $dc = {
	 'echo' => Agent::TCLI::Command->new(
        'name' 		=> 'echo',
        'help' 		=> 'Return what was said.',
        'usage' 	=> 'echo <something> or /echo ...',
        'topic' 	=> 'general',
        'command' 	=> 'pre-loaded',
        'contexts'  => {'UNIVERSAL' => 'echo'},
        'call_style'=> 'state',
        'handler'	=> 'general'
    ),
	 'Hi' => Agent::TCLI::Command->new(
        'name'      => 'Hi',
        'help' 		=> 'Greetings',
        'usage'     => 'Hi/Hello',
        'topic'     => 'general',
        'command' 	=> 'pre-loaded',
        'contexts'  => {'ROOT' => [ qw(Hi hi Hello hello)]},
        'call_style'=> 'state',
        'handler'	=> 'general'
    ),
	 'context' => Agent::TCLI::Command->new(
        'name'      => 'context',
        'help' 		=> "displays the current context",
        'usage'     => 'context or /context',
        'manual'	=> "Context can be somewhat difficult to understand when one thinks of normal command line interfaces that often retain context differently. ".
        	"Context is a way of nesting commands, much like a file directory, to make it easier to navigate. There are a few commands, such as 'help' or 'exit' that are global, ".
        	"but most commands are available only within specific contexts. Well written packages will collect groups of similar commands within a context. ".
        	"For instance, if one had package of attack commands, one would put them all in an 'attack' context. Instead of typing 'attack one target=example.com', ".
        	"one could type 'attack' to change to the attack context then type 'one target=example.com' followed by 'two target=example.com' etc. \n\n".
        	"Furthermore, a well written package will support the setting of default parameters for use within a context. One can then say: \n ".
        	"\tattack \n\tset target=example.com \n\tone \n\ttwo \n\t...\n\n".
        	"The full command 'attack one target=example.com' must always be supported, but using context makes it easier to do repetitive tasks manually as well as ".
        	"allow one to navigate through a command syntax that one's forgotten the details of without too much trouble. \n\n".
        	"Context has a sense of depth, as in how many commands one has in front of whatever one is currently typing. ".
        	"An alias to the context command is 'pwd' which stands for Present Working Depth. ".
        	"Though it may make the Unix geeks happy, they should remember that this is not a file directory structure that one is navigating within.",
        'topic'    	=> 'general',
        'command' 	=> 'pre-loaded',
        'contexts' 	=> {'UNIVERSAL' => [ qw( context pwd ) ]},
        'call_style'=> 'state',
        'handler'	=> 'general'
    ),
	 'Verbose' => Agent::TCLI::Command->new(
        'name'      => 'Verbose',
        'help' 		=> "changes the verbosity of output to logs",
        'usage'     => 'Verbose',
        'topic'    	=> 'admin',
        'command' 	=> 'pre-loaded',
        'contexts' 	=> {'UNIVERSAL' => 'Verbose'},
        'call_style'=> 'state',
        'handler'	=> 'general'
    ),
	 'debug_request' => Agent::TCLI::Command->new(
        'name' 		=> 'debug_request',
        'help' 		=> 'show what the request object contains',
        'usage' 	=> 'debug_request <some other args>',
        'topic' 	=> 'admin',
        'command' 	=> 'pre-loaded',
        'contexts'  => {'UNIVERSAL' => 'debug_request'},
        'call_style'=> 'state',
        'handler'	=> 'general'
    ),
	 'help' => Agent::TCLI::Command->new(
        'name'		=> 'help',
        'help'		=> 'Display help about available commands',
        'usage'		=> 'help [ command ] or /help',
        'manual'	=> 'The help command provides summary information about running a command and the parameters the command accepts. Help with no arguments will list the currently available commands. Help is currently broken in that it only operates within the existing context and cannot be called with a full context.',
        'topic'		=> 'general',
        'command' 	=> 'pre-loaded',
        'contexts'	=> {'UNIVERSAL' => 'help'},
        'call_style'=> 'state',
        'handler'	=> 'help'
    ),
	 'manual' => Agent::TCLI::Command->new(
        'name'		=> 'manual',
        'help'		=> 'Display detailed help about a command',
        'usage'		=> 'manual [ command ]',
        'manual'	=> 'The manual command provides detailed information about running a command and the parameters the command accepts. Manual is currently broken in that it only operates within the existing context and cannot be called with a full context.',
        'topic'		=> 'general',
        'command' 	=> 'pre-loaded',
        'contexts'	=> {'UNIVERSAL' => ['manual', 'man'] },
        'call_style'=> 'state',
        'handler'	=> 'manual'
    ),
	 'status' => Agent::TCLI::Command->new(
        'name' 		=> 'status',
        'help' 		=> 'Display general TCLI control status',
        'usage' 	=> 'status or /status',
        'topic' 	=> 'general',
        'command' 	=> 'pre-loaded',
        'contexts'	=> {'UNIVERSAL' => 'status'},
        'call_style'=> 'state',
        'handler'	=> 'general'
    ),
	 '/' => Agent::TCLI::Command->new(
        'name'      => 'root',
        'help' 		=> "exit to root context, use '/command' for a one time switch",
        'usage'     => 'root or /   ',
        'manual'	=> "root, or '/' for the Unix geeks, will change the context back to root. See 'manual context' for more information on context. ".
        	"Unless otherwise noted, changing to root context does not normally clear out any default settings that were established in that context. \n\n".
        	"One can preceed a command directly with a '/' such as '/exit' to force the root context. ".
        	"Sometimes a context may independently process everything said within the context and, if misbehaving, doesn't provide a way to leave the context. ".
        	"Using '/exit' or '/help' should always work. The example package Eliza is known to have trouble saying Goodbye and exiting properly.",
        'topic'     => 'general',
        'command'   => 'pre-loaded',
        'contexts'  => { 'UNIVERSAL' => ['/','root'] },
        'call_style'=> 'state',
        'handler'	=> 'exit',
    ),
#    {
#        'name'      => 'load',
#        'help' 		=> 'Load a new control package',
#        'usage'     => 'load < PACKAGE >',
#        'topic'     => 'admin',
#        'command'   =>  sub {return ("load is currently diabled")}, #\&load,
#        'call_style'=> 'sub',
#    },
#    {
#        'name'      => 'listcmd',
#        'help' => 'Dump the registered commands in their contexts',
#        'usage'     => 'listcmd (<context>)',
#        'topic'     => 'admin',
#        'command'   => 'pre-loaded',
#        'contexts'   => {'UNIVERSAL'},
#        'call_style'     => 'state',
#        'handler'	=> 'listcmd',
#    },
	 'dumpcmd' => Agent::TCLI::Command->new(
        'name'      => 'dumpcmd',
        'help' 		=> 'Dump the registered command hash information',
        'usage'     => 'dumpcmd <cmd>',
        'topic'     => 'admin',
        'command'   => 'pre-loaded',
        'contexts'  => {'UNIVERSAL' => 'dumpcmd'},
        'call_style'=> 'state',
        'handler'	=> 'dumpcmd',
    ),
	 'nothing' => Agent::TCLI::Command->new(
        'name'      => 'nothing',
        'help' 		=> 'Nothing is as it seems',
        'usage'     => 'nothing',
        'topic'     => 'general',
        'contexts'  => {'ROOT' => 'nothing'},
        'command'   =>  sub { return ("You said nothing, try help") },
        'call_style'=> 'sub',
    ),
	 'exit' => Agent::TCLI::Command->new(
        'name'      => 'exit',
        'help' 		=> "exit the current context, returning to previous context",
        'usage'     => 'exit or /exit',
        'manual'	=> "exit, or '..' for the Unix geeks, will change the context back one level. See 'manual context' for more information on context. ".
        	"Unless otherwise noted, leaving a context does not normally clear out any default settings that were established in that context. \n\n",
        'topic'     => 'general',
        'command'   => 'pre-loaded',
        'contexts'  => {'UNIVERSAL' => [ qw(exit ..)] },
        'call_style'=> 'state',
        'handler'	=> 'exit',
    ),
	 'ip' => Agent::TCLI::Command->new(
        'name'      => 'ip',
        'help' 		=> 'Returns the local ip address',
        'usage'     => 'ip',
        'topic'     => 'net',
        'command' 	=> 'pre-loaded',
        'contexts'  => {'ROOT' => 'ip' },
        'call_style'=> 'state',
        'handler'	=> 'net'
    ),
	 'Control' => Agent::TCLI::Command->new(
        'name'      => 'Control',
        'help' 		=> 'show or set Control variables',
        'usage'     => 'Control show local_address',
        'topic'     => 'admin',
        'command' 	=> 'pre-loaded',
        'contexts'  => {'ROOT' => 'Control' },
        'call_style'=> 'state',
        'handler'	=> 'establish_context'
    ),
	 'show' => Agent::TCLI::Command->new(
        'name'      => 'show',
        'help' 		=> 'show Control variables',
        'usage'     => 'Control show local_address',
        'topic'     => 'admin',
        'command' 	=> 'pre-loaded',
        'contexts'  => {'Control' => 'show' },
        'call_style'=> 'state',
        'handler'	=> 'establish_context'

    ),
	};
	return ( $dc );
}

=item _automethod

Some transports may need to store extra state information related to the
control. Rather than force them to maintain some sort of lookup table,
the Control object can have attributes generated on the fly.
This operates the same as for Request objects and within the
transports themselves. It is exected that the Transport
documentation will describe what is being stored in the Control.

=cut

1;
=back

=head3 INHERITED METHODS

This module is an Object::InsideOut object that inherits from Agent::TCLI::Base. It
inherits methods from both. Please refer to their documentation for more
details.

=head1 AUTHOR

Eric Hacker	 E<lt>hacker at cpan.orgE<gt>

=head1 BUGS

SHOULDS and MUSTS are currently not enforced.

Test scripts not thorough enough.

Probably many many others.

=head1 LICENSE

Copyright (c) 2007, Alcatel Lucent, All rights resevred.

This package is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=cut

