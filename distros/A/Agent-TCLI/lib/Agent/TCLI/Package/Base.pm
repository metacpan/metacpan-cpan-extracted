package Agent::TCLI::Package::Base;
#
# $Id: Base.pm 62 2007-05-03 15:55:17Z hacker $
#
=head1 NAME

Agent::TCLI::Package::Base - Base object for other Agent::TCLI::Package objects

=head1 SYNOPSIS

Base object for Commands. May be used directly in a command collection
or may be extended for special functionality. Note that the Control and
Library will not recognize any class extension without also being modified.

=head1 DESCRIPTION

This needs much more elaboration. For now, please use the source
of existing command packages. I apologize for the inconvenience.

=head1 INTERFACE

=cut

use warnings;
use strict;
use Carp;
use Object::InsideOut qw(Agent::TCLI::Base);

use POE;
use Scalar::Util  qw(blessed looks_like_number);
use Getopt::Lucid;
use YAML::Syck;
use XML::Simple;
use File::ShareDir;
#use FormValidator::Simple;

$YAML::Syck::Headless = 1;
$YAML::Syck::SortKeys = 1;

our $VERSION = '0.030.'.sprintf "%04d", (qw($Id: Base.pm 62 2007-05-03 15:55:17Z hacker $))[2];

=head2 ATTRIBUTES

The following attributes are accessible through standard accessor/mutator
methods unless otherwise noted

=over

=item name

The name of the package. This is the word that is used to refer to the package POE::Session.
B<name> should only contain SCALAR type values.

=cut
my @name		:Field
				:Arg('name'=>'name','default'=>'base')
				:Acc('name');

=item commands

An array of the command objects in this package.

=cut
my @commands	:Field
				:Arg('commands')
				:Get('commands')
				:Type('HASH');

=item parameters

A hash of the parameters used in this package. Often parameters are shared
accross individual commands, so they are defined within the Package.
They are refered to by each command in the package.
B<parameters> should only contain hash values.

=cut
my @parameters	:Field
				:Type('HASH')
				:Arg('parameters')
				:Get('parameters');

my @session 	:Field
				:Arg('session')
				:Get('session')
				:Weak;
#				:Type('POE::Session');

=item controls

A hash of hashes keyed on control for storing stuff.

=cut
my @controls		:Field;

=item requests

A hash collection of requests that are in progress

=cut
my @requests		:Field
					:Type('HASH')
					:Arg('name' => 'requests', 'default' => { } )
					:Acc('requests');

=item wheels

A hash of wheels keyed on wheel ID.
B<wheels> values should only be POE::Wheels.

=cut
my @wheels			:Field;



# Standard class utils are inherited

=back

=head2 METHODS

Most of these methods are for internal use within the TCLI system and may
be of interest only to developers trying to enhance TCLI.

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

				establish_context
				settings
				show
				)],
      		],
		)
	 unless defined( $args->{'session'} );
}

# This POE event handler is called when POE starts up a Package.
# The B<_start> method is :Cumulative within OIO. Ideally, most command packages
# could use this Base _start method without implementing
# their own. However there seems to be a race condition between the POE
# initialization and the OIO object initialization. Until this is debugged
# one will probably have to have this _start method in every package.

sub _start :Cumulative {
	my ($kernel,  $self,  $session) =
      @_[KERNEL, OBJECT,   SESSION];

	# are we up before OIO has finished initializing object?
	if (!defined( $self->name ))
	{
		$self->Verbose("_start: OIO not done re-starting");
		$kernel->yield('_start');
#		$kernel->delay('_start', 1 );
		return;
	}
	$self->Verbose("_start: ".$self->name()." starting");
	# There is only one command object per TCLI
    $kernel->alias_set($self->name);
}

# This POE event handler is used to initiate a shutdown of the Control.

sub _shutdown :Cumulative {
	my ($kernel,  $self,) =
      @_[KERNEL, OBJECT,];
	$self->Verbose("_shutdown:base ".$self->name." shutting down");

	$self->Verbose("shutdown:base deleting wheels ",2);
    foreach my $wheel ( keys %{ $wheels[$$self] } )
    {
    	$self->SetWheel($wheel);
    }
    foreach my $control ( keys %{ $controls[$$self] } )
    {
    	$self->SetControl($control);
    }
    # clear all alarms you might have set
    $kernel->alarm_remove_all();

    return ("_shutdown:base ".$self->name )
}

#This POE event handler is called when POE stops a Package.
#The B<_stop> method is :Cumulative within OIO.

sub _stop :Cumulative {
    my ($kernel,  $self,) =
      @_[KERNEL, OBJECT,];

	$self->Verbose("_stop: ".$self->name." stopping");

	return($self->name.":_stop complete ");
}

#Just a placeholder that does nothing but collect unhandled child events
#to keep them out of default.

sub _child {
  my ($kernel,  $self, $session, $id, $error) =
    @_[KERNEL, OBJECT,  SESSION, ARG1, ARG2 ];

   $self->Verbose("child: pid($id) ");
}

=item establish_context

This POE event handler is the primary way to set context with a command.
Just about any command that has subcommands will use this method as it's handler.
An exception would be a command that sets an single handler to process all
subcoammnds/args using the 'A*' context. See the Eliza package for an example of
how to establish that type of context.

=cut

sub establish_context {
    my ($kernel,  $self, $sender, $request, ) =
      @_[KERNEL, OBJECT,  SENDER,     ARG0, ];
	$self->Verbose("establish_context: ".$self->name." for request(".
		$request->id().")");

	my $txt;
	# if we have args, then the command is invalid
	if ( $request->depth_args > 0 )
	{
		$txt .= "Invalid input: ".$request->input;
		$self->Verbose("establish_context: Invalid input (".$request->input.")"  );
		$request->Respond($kernel, $txt, 404) if $txt;
		return;
	}

	# we don't know how deep we're in already. So we'll force a full context shift.
	# by sending the entire command array back, which is revesred.
	my @context = reverse (@{$request->command});

	# We don't actualy set the controls context, but let change context do that.
	# It will also inform the user of change.

   	# Post context back to sender (Control)
   	$kernel->call( $sender => 'ChangeContext' => $request, \@context );
	$self->Verbose("establish_context: setting context to "
			.join(' ',@context)." ",2);

}

=item show

This POE event handler is the default show for packages.
It will accept an argument for the setting to show. It will also take an
argument of all or * and show all settings.

The parameter must be defined in the show Command entry's parameters or it will
not be shown. There must also be a OIO Field defined with the same name.
One may write their own show method if this is not sufficient.

One must still define the show Command within one's package to use this. One
must also load the show event handler in the Package's session.

=cut

sub show {
    my ($kernel,  $self, $sender, $request, ) =
      @_[KERNEL, OBJECT,  SENDER,     ARG0, ];
	$self->Verbose("show: request(".$request->id.") ",2);

	my ($txt, $code, $what, $var);
	# calling with show as a command, that is the handler for show is show.
	if ( $request->command->[0] eq 'show' ) 	# cmd1 show arg
												# cmd1 attacks show <arg>
	{
		$what = $request->args->[0];
	}

	$self->Verbose("show: what(".$what.") request->args",1,$request->args);

	ATTR: foreach my $attr ( keys %{ $self->commands->{'show'}->parameters } )
	{
		if ( $what eq $attr || $what =~ qr(^(\*|all)$))
		{
			if ( $self->can( $attr ) && defined( $self->$attr) )
			{
				my $ref = ref($self->$attr);
				my $show = ( defined($self->parameters ) &&
					defined($self->parameters->{ $attr } ) &&
					defined($self->parameters->{ $attr }->show_method ) )
					? $self->parameters->{ $attr }->show_method
					: '';
				$self->Verbose("show attr($attr) ref($ref) show($show)",1);
				# simple scalar
				if ( not $ref)
				{
					$txt .= "$attr: ".$self->$attr." \n";
					$code = 200;
				}
				# is it an object and show_method is defined?.
				elsif ( $ref =~ qr(::) && blessed( $self->$attr )
					&& $show )
				{
					$txt .= "$attr: ".$self->$attr->$show."\n";
					$code = 200;
				}
				# is it an object with dump? Probably OIO.
				elsif ( $ref =~ qr(::) && blessed($self->$attr)
					&& $self->$attr->can( 'dump') )
				{
					$var = $self->$attr->dump(0);
					$txt .= Dump($var)."\n";
					$code = 200;
				}
				elsif ( $ref =~ qr(HASH) )
				{
					foreach my $key ( sort keys %{$self->$attr} )
					{
						my $subref = ref($self->$attr->{ $key }   );
						$self->Verbose("show key($key) subref($subref)",0);
						# simple scalar
						if ( not $subref )
						{
							$txt .= "$attr ->{ $key }: ".$self->$attr->{$key}." \n";
							$code = 200;
						}
						# is it an object and show_method is defined?.
						elsif ( $subref =~ qr(::) &&
							blessed($self->$attr->{ $key }) &&
							defined($show) )
						{
							$txt .= "$attr: ".$self->$attr->{$key}->$show."\n";
							$code = 200;
						}
						# is it an object with dump? Probably OIO.
						elsif ( $subref =~ qr(::) &&
							blessed($self->$attr->{ $key }) &&
							$self->$attr->{ $key }->can( 'dump') )
						{
							$var = $self->$attr->{$key}->dump(0);
							$txt .= Dump($var)."\n";
							$code = 200;
						}
						# some other object, array or hash
						else
						{
							$var = $self->$attr->{$key};
							$txt .= Dump($var)."\n";
							$code = 200;
						}
					}
				}
				elsif ( $ref =~ qr(ARRAY) )
				{
					my $i = 0;
					foreach my $val ( @{$self->$attr} )
					{
						my $subref = ref( $val );
						# simple scalar
						if ( not $subref )
						{
							$txt .= "$attr ->[ $i ]: ".$val." \n";
							$code = 200;
						}
						# is it an object and show_method is defined?.
						elsif ( $subref =~ qr(::) &&
							blessed($val) &&
							defined($show) )
						{
							$txt .= "$attr: ".$val->$show."\n";
							$code = 200;
						}
						# is it an object with dump? Probably OIO.
						elsif ( $subref =~ qr(::) &&
							blessed($val) &&
							$val->can( 'dump') )
						{
							$var = $val->dump(0);
							$txt .= Dump($var)."\n";
							$code = 200;
						}
						# some other object, array or hash
						else
						{
							$txt .= Dump($val)."\n";
							$code = 200;
						}
					}
				}
				# some other object
				else
				{
					$var = $self->$attr;
					$txt .= Dump($var)."\n";
					$code = 200;
				}
			}
			elsif ( $self->can( $attr )  )
			{
		  		$txt = $what.": #!undefined";
				$code = 200;
			}
			else # should get here, but might if parameter error.
		  	{
  				$txt = $what.": #!ERROR does not exist";
  				$code = 404;
  			}
		}
	}

	# if we didn't find anything at all, then a 404 is returned
  	if (!defined($txt) || $txt eq '' )
  	{
  		$txt = $what.": #!ERROR not found";
  		$code = 404;
  	}

	$request->Respond($kernel, $txt, $code);
}

=item settings

This POE event handler executes the set commands.

=cut

sub settings {  # Can't call it set
    my ($kernel,  $self, $sender, $request, ) =
      @_[KERNEL, OBJECT,  SENDER,     ARG0, ];

	my $txt = '';
	my ($param, $code);
	my $command = $request->command->[0];
	# called directly because $command may be an alias and not the real name
	my $cmd = $self->commands->{'set'};

	# TODO a way to unset/restore defaults....

	# break down and validate args
	return unless ($param = $cmd->Validate($kernel, $request) );

	$self->Verbose("set: param dump",1,$param);

	# Get meta data
	my $meth = $self->meta->get_methods();

	foreach my $attr ( keys %{$param} )
	{
		# param will have all fields defined, gotta skip the empty ones.
		# Can't use ne due to NetAddr::IP bug
		next unless (defined($param->{$attr})
#			&& !($param->{$attr} eq '')  # diabled, since we should be OK now.
			);

		$self->Verbose("settings: setting attr($attr) => ".
			$param->{$attr}." ");

		# is there a field type object for this attr?
		if ( ref($param->{$attr}) eq '' &&
			exists( $meth->{$attr} ) &&
			exists( $meth->{$attr}{'type'} ) &&
			$meth->{$attr}{'type'} =~ /::/ )
		{
			my $class = $meth->{$attr}{'type'};
			$self->Verbose("set: class($class) param($param) attr($attr) ");
			my $obj;
			eval {
				no strict 'refs';
				$obj = $class->new($param->{$attr});
			};
			# If it went bad, error and return nothing.
			if( $@ )
			{
				$@ =~ qr(Usage:\s(.*)$)m ;
				$txt = $1;
				$self->Verbose('set: new '.$class.' got ('.$txt.') ');
				$request->Respond($kernel,  "Invalid: $attr !", 400);
				return;
			}
			eval { $self->$attr($obj) };
			if( $@ )
			{
				$@ =~ qr(Usage:\s(.*)$)m ;
				$txt = $1;
				$self->Verbose('set: new '.$class.' got ('.$txt.') ');
				$request->Respond($kernel,  "Invalid: $attr !", 400);
				return;
			}
			$txt .= "Set ".$attr." to ".$param->{$attr}." \n";
			$code = 200;

		}
		else
		{
			eval { $self->$attr( $param->{$attr} ) };
			if( $@ )
			{
				$@ =~ qr(Usage:\s(.*)$)m ;
				$txt = $1;
				$self->Verbose('set: $self->'.$attr.'( '.$param.'->{ '.
					$attr.' } got ( '.$txt.') ');
				$request->Respond($kernel,  "Invalid: $attr !", 400);
				return;
			}
			$txt .= "Set ".$attr." to ".$param->{$attr}." \n";
			$code = 200;
		}
	}

  	if (!defined($txt) || $txt eq '' )
  	{
  		$txt = "Invalid: ".join(', ',keys %{$param} );
  		$code = 404;
  	}

	$request->Respond($kernel, $txt, $code);
}

sub GetControl {
	my ($self, $id ) = @_;
	return ( $controls[$$self]->{$id}{'control'} )
		if defined( $controls[$$self]->{$id}{'control'} );
	return (0);
}

sub SetControl {
	my ($self, $control) = @_;
	if ( ref($control) =~ /control/ )
	{
		$controls[$$self]->{$control->id}{'control'} = $control;
	}
	else
	{
		delete ($controls[$$self]->{$control}{'control'} );
		delete ($controls[$$self]->{$control} );
	}
	return
}

sub GetControlKey {
	my ($self, $control, $key) = @_;
	if ( ref($control) =~ /control/ )
	{
		return ( $controls[$$self]->{$control->id}{$key} );
	}
	else
	{
		return ( $controls[$$self]->{$control}{$key} );
	}
}

sub SetControlKey {
	my ($self, $control, $key, $value) = @_;
	$controls[$$self]->{$control->id}{$key} = $value;
	return
}

sub GetWheel {
	my ($self, $id, $sp) = @_;
	return ( $wheels[$$self]->{$id}{'wheel'},
			 $wheels[$$self]->{$id}{'sender'},
			 $wheels[$$self]->{$id}{'postback'} )
		if (defined( $wheels[$$self]->{$id}{'wheel'}) && $sp );

	return ( $wheels[$$self]->{$id}{'wheel'} )
		if ( defined( $wheels[$$self]->{$id}{'wheel'} ) );

	return (0);
}

sub SetWheel {
	my ($self, $wheel) = @_;
	if ( ref($wheel) =~ /POE::Wheel/ )
	{
		$wheels[$$self]->{$wheel->ID}{'wheel'} = $wheel;
	}
	else # it is just a wheel ID
	{
		delete ($wheels[$$self]{$wheel}{'wheel'} );
		delete ($wheels[$$self]{$wheel} );
	}
	return
}

sub GetWheelKey {
	my ($self, $wheel, $key) = @_;
	if ( ref($wheel) =~ /POE::Wheel/ )
	{
		return ( $wheels[$$self]->{$wheel->ID}{$key} );
	}
	else
	{
		return ( $wheels[$$self]->{$wheel}{$key} );
	}
}

sub SetWheelKey {
	my ($self, $wheel, $key, $value) = @_;
	if ( ref($wheel) =~ /POE::Wheel/ )
	{
		$wheels[$$self]->{$wheel->ID}{$key} = $value;
	}
	else
	{
		$wheels[$$self]->{$wheel}{$key} = $value;
	}
	return 1;
}


# Input validation methods. Returns false or error message.
# These are all deprecated. Use Contraints and Command->Validator instead.

sub NotPosInt {
	my ($self,$value,$name,$set) = @_;
	$name = "Parameter" unless defined($name);
	return ('') unless (defined ($value) && $value ne '');
	return($name." is not a number: got '$value'  \n") unless (Scalar::Util::looks_like_number($value) );
    return($name." is not an integer: got '$value'  \n") unless(int($value) == $value);
    return($name." is not positive: got '$value'  \n") unless ( $value >= 0);
	if (defined($set))
	{
		$self->$name($value) 	if ($set eq 'set');

	}
	return ('');
}

sub NotNumeric {
	my ($self,$value,$name,$set) = @_;
	$name = "Parameter" unless defined($name);
	return ('') unless (defined ($value) && $value ne '');
	return($name." is not a number: got '$value' \n") unless (Scalar::Util::looks_like_number($value) );
	$self->$name($value) 	if ($set);
	return ('');
}

sub NotScalar {
	my ($self,$value,$name,$set) = @_;
	$name = "Parameter" unless defined($name);
	return ('') unless (defined ($value) && $value ne '');
	return($name." is not a scalar: got '$value'  \n") unless ( ref($value) eq '' || ref($value) eq 'SCALAR_REF' );
	$self->$name($value) 	if ($set);
	return ('');
}

sub NotRange {
	my ($self,$value,$name,$set) = @_;
	$name = "Parameter" unless defined($name);
	return ('') unless (defined ($value) && $value ne '');
	return($name." must contain only digits or ,-:  got '$value' \n") unless ( $value !~ /[^0-9,:-]/ );
    return($name." must only have positive numbers: got '$value'  \n") unless ($value !~ /^-/ && $value !~ /[,:]-/);
    return($name." has invalid ranges: got '$value' \n") unless ( $value !~ /\d+[-:]\d+[-:]\d+/ && $value !~ /^[,:]/ );
	$self->$name($value) 	if ($set);
	return ('');
}

sub NotRegex {
	my ($self,$value,$name,$set) = @_;
	$name = "Parameter" unless defined($name);
	return ('') unless (defined ($value) && $value ne '');
	return($name." is not a valid regex: got '$value' \n")
		unless ( ref ( $value ) eq 'Regexp' );
	$self->$name($value) 	if ($set);
	return ('');
}

sub NotType {
	my ($self,$value,$name,$ref,$set) = @_;
	$name = "Parameter" unless defined($name);
	$ref = (ref($ref) eq 'Regexp') ? $ref : qr($ref);
	return ('') unless (defined ($value) && $value ne '');
	return($name." is not a valid type: got '$value' \n")
		unless ( ref ( $value ) =~ $ref );
	$self->$name($value) 	if ($set);
	return ('');
}

sub NotWithin
{
  # Taken from Test::Data::Within v 0.0.x
  # Update accordingly.  :)
  my ($self, $value, $range) = @_;
  my $txt;

  return 1 unless (defined($value) && defined($range));
  if ($range =~ /,/)
  {
	  my @list = split /,/,$range;
	   foreach my $item (@list)
	   {
	     my $res = $self->NotWithin($value,$item);
		 return (0) unless $res;
		 $txt .= $res unless $res == 1;
	   }
	   # No item matched
	   return (1) unless $txt;
	   return ($txt);
  }

  # todo trap min/max non numeric errors below.

  my ($min, $max, $more);
  # using a range divider of : allows negative numbers in ranges
  if ($range =~ /:/)
  {
	($min, $max, $more) = split /:/,$range;
  }
  else
  {
	($min, $max, $more) = split /-/,$range;
  }

  if ( !defined($max))
  {
    return (0) if ($value == $min);
    $txt .= " not $value == $min \n" if $self->verbose;
  }
  else
  {
    return (0) if ($value >= $min) && ($value <= $max);
    $txt .= " not $min <= $value <= $max \n" if $self->verbose;
  }
  # nothing matched
   return (1) unless $txt;
   return ($txt);

} # End sub NotWithin

sub RawCommands {
	my $self = shift;
	# This is a little kludge to get one command package load routine
	# by default RawCommands just returns an array of one
	# but may be changed by subclasses
	my @cmdarray;
	foreach my $cmd ( @{$commands[$$self]}  )
	{
		push(@cmdarray, $cmd->RawCommand );
	}
	return ( \@cmdarray );
}

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

	return (0);
}

sub LoadYaml {
	my ($self, $yaml) = @_;
	$self->Verbose("LoadYaml: Loading" );

	# hmmm, should trap for errors someday.
	my @loadees = Load($yaml);

	$self->Verbose("LoadYaml: Loadees dump",3,\@loadees );

	# We can only handle an array of loadees.
	foreach my $loadee ( @loadees )
	{
		if ( ref($loadee) ne 'HASH' )
		{
			$self->Verbose("LoadYaml: Bad yaml, not a hash",0);
			return;
		}
			# using regex to allow subclassing later.
			foreach my $object ( keys %{$loadee} )
			{
			if ( $object =~ /Parameter/ )
			{
				$self->AddParameter($object,$loadee->{$object});
			}
			elsif ( $object =~ /Command/ )
			{
				$self->AddCommand($object,$loadee->{$object});
			}
			else
			{
				$self->Verbose("LoadYaml: Unknown Object".$object,0);
				return;
			}
		}
		# The first entry ought to tell us what it wants to be.
	}
	return 1;
}

sub LoadXMLFile {
	my ($self, $xml_file) = @_;
	$self->Verbose("LoadXmlFile: Loading" );

	my $class = ref($self) || $self;

	$xml_file = File::ShareDir::module_file($class,'config.xml')
		unless defined($xml_file);

	# hmmm, should trap for errors someday.
	my $loadees = XMLin($xml_file,
		KeyAttr 	=> [],
		SearchPath 	=> \@INC,
	);

	$self->Verbose("LoadYaml: Loadees dump",3,\$loadees );

	# We can only handle an array of loadees.
	foreach my $loadee ( @{$loadees->{'Parameter'} } )
	{
		if ( ref($loadee) ne 'HASH' )
		{
			$self->Verbose("LoadXMLFile: Bad xml, Parameter not a hash",0);
			return;
		}
		else
		{
			$self->AddParameter('Agent::TCLI::Parameter',$loadee);
		}
	}
	foreach my $loadee ( @{$loadees->{'Command'} } )
	{
		if ( ref($loadee) ne 'HASH' )
		{
			$self->Verbose("LoadXMLFile: Bad xml, Command not a hash",0);
			return;
		}
		else
		{
			$self->AddCommand('Agent::TCLI::Command',$loadee);
		}
	}
	return 1;
}


sub AddParameter {
	my ($self, $object, $args) = @_;
    my $class = ref($self) || $self;

	my $name = $args->{'name'};

	if ( !defined($name ) )
	{
		$self->Verbose("AddParameter: No name!",0);
		return;
	}

	$self->Verbose("AddParameter: adding $object $name ");
	# using $object here to allow parameter subclassing to work
    $parameters[$$self]{ $name } = $object->new(
    	'verbose' 		=> $self->verbose,
    	'do_verbose' 	=> $self->do_verbose,
    	$args,
    	);

#    $parameters[$$self]{ $name }->verbose($self->verbose);
#    $parameters[$$self]{ $name }->do_verbose($self->do_verbose);

	# Create field if there isn't a field in the package for this parameter
	if (! $self->can($name) )
	{
		my $arg;
		if (exists($args->{'default'}))
		{
			$arg = ":Arg('name'=>'$name', 'default'=> '$args->{'default'}') ";
		}
		else
		{
			$arg = ":Arg('name'=>'$name') ";
		}

		my $type = exists($args->{'class'})
			? ":Type('".$args->{'class'}."') "
			: '';

		$class->create_field('@'.$name, ":Acc($name) ".$arg.$type);

		# Add in defaut value, since if we're after preinit, it won't
		# be there.
		$self->$name($args->{'default'}) if (exists($args->{'default'}));
	}
    return 1;
}

sub AddCommand {
	my ($self, $object, $args) = @_;

	my $name = $args->{'name'};

	if ( !defined($name ) )
	{
		$self->Verbose("AddCommand: No name!",0);
		return;
	}

	$self->Verbose("AddCommand: adding $name ");
	$self->Verbose("AddCommand: adding $name args dump ",3,$args);
    $commands[$$self]{ $name } = $object->new(
    	'verbose' 		=> $self->verbose,
    	'do_verbose' 	=> $self->do_verbose,
    	$args,
    	);

	$self->Verbose("AddCommand: adding $name command dump ".$commands[$$self]{ $name }->dump(1),3);

	# Parameters were just stubs. Put in proper references.
	if ( defined( $commands[$$self]{ $name }->parameters ) )
	{
		foreach my $paramkey ( keys %{ $commands[$$self]{ $name }->parameters } )
		{
			if ( exists( $parameters[$$self]->{ $paramkey } ) &&
				blessed($parameters[$$self]->{ $paramkey }) =~ qr(Parameter) )
			{
				$commands[$$self]{ $name }->parameters->{ $paramkey } =
					$parameters[$$self]->{ $paramkey };
			}
			else # All this is just for helping to debug problems easier
			{
				$self->Verbose("AssCommand: $name Parameter '$paramkey' not defined. Dumping",0 );
				foreach my $parameter ( %{$parameters[$$self]} )
				{
					if ( blessed($parameter) )
					{
						$self->Verbose( $parameter->dump(1),0 );
					}
					else
					{
						$self->Verbose( $parameter,0 );
					}
				}

				croak("AddCommand: $name Parameter '$paramkey' not defined")
			}
		}
	}

    return 1;
}

sub AddCommands {
	my ($self, @cmds) = @_;

	# Hmmm perhaps some validation should ocurr in the future?
	foreach my $cmd (@cmds)
	{
		$commands[$$self]{ $cmd->name } = $cmd;
	}
	return 1;
}

sub YamlPrint {
	my ($self, $ref ) = @_;
	return Dump($ref);
}

1;

=back

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
