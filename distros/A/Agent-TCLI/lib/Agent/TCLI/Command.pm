package Agent::TCLI::Command;
#
# $Id: Command.pm 59 2007-04-30 11:24:24Z hacker $
#
=head1 NAME

Agent::TCLI::Base - Base object for other TCLI objects

=head1 SYNOPSIS

Tedious method:

package Agent::TCLI::Package::MyCommand

sub _init {
	my $self = shift;

	my $test_verbose = Agent::TCLI::Parameter->new(
    	constraints => ['UINT'],
    	help => "an integer for verbosity",
    	manual => 'The verbose manual.',
    	name => 'test_verbose',
    	aliases => 'verbose|v',
    	type => 'Counter',
	);

	my $paramint = Agent::TCLI::Parameter->new(
    	constraints => ['UINT'],
    	help => "an integer for a parameter",
    	manual => 'The integer parameter.',
	    name => 'paramint',
    	type => 'Param',
	);

	my $cmd1 = Agent::TCLI::Command->new(
	        'name'		=> 'cmd1',
	        'contexts'	=> {'/' => 'cmd1'},
    	    'help' 		=> 'cmd1 help',
        	'usage'		=> 'cmd1 usage',
        	'topic'		=> 'test',
        	'call_style'=> 'session',
        	'command'	=> 'test1',
	        'handler'	=> 'cmd1',
	        'parameters' => {
	        	'test_verbose' 	=> $test_verbose
	        	'paramint'	=> $paramint,
	        	},
			'verbose' 	=> 0,
	);

	$self->parameters->{'test_verbose'} = $test_verbose;
	$self->parameters->{'paramint'} = $paramint;
	$self->commands->{'cmd1'} = $cmd1;
}

Easier method

package Agent::TCLI::Package::MyCommand

sub _init {
	my $self = shift;

	$self->LoadYaml(<<'...');
---
Agent::TCLI::Parameter:
  name: test_verbose
  constraints: UINT
  help: an integer for verbosity
  manual >
   The verbose manual.
 name: test_verbose
 aliases: verbose|v
 type: Counter
---
Agent::TCLI::Parameter:
  name: paramint
  constraints: UINT
  help: an integer for a parameter
  manual >
    The integer parameter.
  type => Param
---
Agent::TCLI::Command:
  name: cmd1
  contexts:
    '/' : cmd1
  help: cmd1 help
  usage: cmd1 usage
  topic: test
  call_style: session
  command: test1
  handler: cmd1
  parameters:
    test_verbose: verbose
    paramint: paramint
...
}

=head1 DESCRIPTION

Base object for Commands. May be used directly in a command collection
or may be extended for special functionality. Note that the Control and
other components will not recognize any class extension without
also being modified.

=head1 INTERFACE

Commands are usually loaded into Packages to provide their functionality. One
Package may have many commands and parameters. Rather than writing these
as separate object new statements, one can use YAML to load in batches
of Parameters and Commands into the Package. Order is important, be sure
to load or define Parameters before Commands that use them.

=cut

use warnings;
use strict;

our $VERSION = '0.030.'.sprintf "%04d", (qw($Id: Command.pm 59 2007-04-30 11:24:24Z hacker $))[2];

use Object::InsideOut qw(Agent::TCLI::Base);
use Getopt::Lucid qw(:all);
use FormValidator::Simple;

=head2 ATTRIBUTES

The following attributes are accessible through standard named accessor/mutator
methods unless otherwise noted

=over

=item name

The name of the command. This is the word that is used to call the command.
It should be long enough to be descriptive. Use aliases for shortenned
versions or abbreviations.

The name is also the key used in a Package's commands hash. Thus is must
be unique within a package.

B<set_name> will only accept SCALAR type values.

=cut
my @name		:Field	:All('name');

=item topic

The general topic heading that the command will be listed under.
Most applicable to help menus.
B<set_topic> will only accept SCALAR type values.

=cut
my @topic		:Field	:All('topic');

=item help

Brief text to decribe the function of the command. This should be
a one line description.
B<set_help> will only accept SCALAR type values.

=cut
my @help		:Field	:All('help');

=item usage

Brief illustration of usage. Complex commands may want to show how to call
help / manual instead.
B<set_usage> will only accept SCALAR type values.

=cut
my @usage		:Field	:All('usage');

=item manual

A long desciption of the command and its use. This text will be followed
by the command's parameter's manul sections if provided.
B<manual> will only contain scalar values.

=cut
my @manual			:Field
#					:Type('scalar')
					:All('manual');

=item command

A reference to the sub routine that will execute the command
or the name of the package session that will run the command.

=cut
my @command		:Field	:All('command');

=item start

Deprecated: A reference to a subroutine that is necessary to intialize the command at control startup.
B<start> will only accept CODE type values.

=cut
my @start		:Field	:All('start')
				:Type('CODE');
=item stop

Deprecated: A code reference for shutting down anything as the control shuts down.
B<stop> will only accept CODE type values.

=cut
my @stop		:Field	:All('stop')
				:Type('CODE');
=item handler

A code reference for a response handler if necessary for a
POE event driven command

=cut
my @handler		:Field	:All('handler');

=item call_style

This is a holdover to facilitate migration from the older style method
of calling commands with an oob, to the new POE parameter use. The value
'poe' means the command is called directly with the normal POE KERNEL
HEAP and ARGs. 'session' means that a POE event handler is called.
B<call_style> will only accept SCALAR type values.

=cut
my @call_style	:Field	:All('call_style');

=item contexts

A hash of the contexts that the command may be called from. This needs to
be written up much better in a separate section, as it is very complicated.
B<contexts> will only accept hash type values.

=cut
my @contexts	:Field
				:All('contexts')
				:Type('Hash');

=item parameters

A hash of parameter objects that the command accepts.
B<parameters> will only contain hash values.

=cut
my @parameters		:Field
					:Type('hash')
					:Arg('name'=>'parameters', 'default'=> { } )
					:Acc('parameters');

=item required

A hash containing the names of the required parameters.
B<required> will only contain HASH values.

=cut
my @required		:Field
					:Type('HASH')
					:Arg('name'=>'required', 'default'=> { } )
					:Acc('required');

=item cl_options

These are command line options that will be issued every time the
command is called. They will begin the value returned by
BuildCommandLine. Make sure that they are not available as
parameters for this command. There is no checking for
duplicates and that will likely cause errors.
B<cl_options> should only contain scalar values.

=cut
my @cl_options		:Field
#					:Type('scalar')
					:All('cl_options');

# Standard class utils are inherited

=back

=head2 METHODS

These methods assist Package authors in common functioanlity needed to support
a command. In some cases they are used internally by other parts of the
Agent::TCLI system.

=over

=item Usages (  context  )

Get a list of how this command is called in the given context.

A command may be aliased to several different terms in a given context
or it may be aliased to different terms in different contexts. This
method takes a context and returns the list of aliases for the command.
It is used internally to support help.

=cut

sub Usages {
	my ($self, $c) = @_;
	$self->Verbose("Usages: \$c dump",3,$c);

	my @aliases;

	# All* handler contexts are not handled because that doesn't make sense here.

	# This handles contexts situations that are not capable of being parsed
	# by Control.pm, but there doesn't appear to be any good reason to complicate
	# the code to filter them out here.

	# Root context
	if ( $c->[0] eq '/' && defined( $contexts[$$self]{'/'} ) )
	{
		# This would allow hashes under / which is not supported by Control.pm
		push( @aliases , @{ $self->Aliases( $contexts[$$self]{'/'} ) } );
	}
	# Global context. Only return if asked for.
	elsif ( $c->[0] eq '*' && defined( $contexts[$$self]{'*'} ) )
	{
		# This would allow hashes under * which is not supported by Control.pm
		push( @aliases , @{ $self->Aliases( $contexts[$$self]{'*'} )  } );
	}
	elsif ( @{$c} == 1 )
	{
		if ( defined( $contexts[$$self]{ $c->[0] } ) )
		{
			push( @aliases , @{ $self->Aliases( $contexts[$$self]{ $c->[0] } ) } );
		}

#		elsif ( defined( $contexts[$$self]{ '*U' } ) )
#		{
#			# This would allow hashes under *U which is not supported by Control.pm
#			$aliases =  $self->Aliases( $contexts[$$self]{ '*U' } );
#		}
	}
	elsif ( @{$c} == 2 )
	{
		if ( defined( $contexts[$$self]{ $c->[0] }{ $c->[1] } ) )
		{
			push( @aliases , @{ $self->Aliases( $contexts[$$self]{ $c->[0] }{ $c->[1] } ) } );
		}

		if ( defined( $contexts[$$self]{ $c->[0] }{ '*U' } ) )
		{
			# This would allow hashes under *U which is not supported by Control.pm
			push( @aliases , @{$self->Aliases( $contexts[$$self]{ $c->[0] }{ '*U' } ) } );
		}
	}
	elsif ( @{$c} == 3 )
	{
		if ( defined( $contexts[$$self]{ $c->[0] }{ $c->[1] }{ $c->[2] } ) )
		{
			push( @aliases , @{ $self->Aliases( $contexts[$$self]{ $c->[0] }{ $c->[1] }{ $c->[2] } ) } );
		}

		if ( defined( $contexts[$$self]{ $c->[0] }{ $c->[1] }{ '*U' } ) )
		{
			# This would allow hashes under *U which is not supported by Control.pm
			push( @aliases , @{ $self->Aliases( $contexts[$$self]{ $c->[0] }{ $c->[1] }{ '*U' } ) } );
		}
	}
	elsif ( @{$c} == 4 )
	{
		# any hashes at this point are not supported by Control.pm
		if ( defined( $contexts[$$self]{ $c->[0] }{ $c->[1] }{ $c->[2] }{ $c->[3] } ) )
		{
			push( @aliases , @{ $self->Aliases( $contexts[$$self]{ $c->[0] }{ $c->[1] }{ $c->[2] }{ $c->[3] } ) } );
		}
		if ( defined( $contexts[$$self]{ $c->[0] }{ $c->[1] }{ $c->[2] }{ '*U' } ) )
		{
			# This would allow hashes under *U which is not supported by Control.pm
			push( @aliases , @{ $self->Aliases( $contexts[$$self]{ $c->[0] }{ $c->[1] }{ $c->[2] }{ '*U' } ) } );
		}
	}

	$self->Verbose("Usages: out \$c dump",4,$c);
	$self->Verbose("Usages: out aliases dump",4,\@aliases);
	$self->Verbose("Usages: contexts dump",3, $contexts[$$self] ) unless @aliases;
	return ( \@aliases );
} # End Usages

=item Aliases (  context_hash_key  )

Return aliases for specific context hash key.

An internal method that takes a context hash key and returns all the
aliases for that specific key. The aliases could be an array, hash
or scalar and this function simplifies that logic. It returns a
hash keyed on aliases of the command object.

If one has only a context, then use Usages which will call
Aliases correctly.

=cut

sub Aliases {
	my ($self, $context_hash_key) = @_;
	$self->Verbose("Aliases: context_hash_key dump",3,$context_hash_key);
	my @aliases;
	if ( ref( $context_hash_key ) =~ /ARRAY/ )
	{
		# There is a list of aliases to add.
		push( @aliases ,  @{$context_hash_key} );
#		%aliases = map { $_ => $self }  @{$context_hash_key} };
	}
	elsif ( ref( $context_hash_key ) =~ /HASH/ )
	{
		# There are context shifts to add.
		foreach my $key (keys %{$context_hash_key} )
		{
			push( @aliases , $key  ) unless ( $key =~ qr(\*U) );
		}
#		%aliases = map { $_ => $self }  keys %{$context_hash_key};
	}
	else
	{
		# There is a single alias to add.
		push( @aliases , $context_hash_key );
#		%aliases = ( $context_hash_key => $self );
	}
	return (\@aliases);
} # End Aliases

#sub RawCommand {
#	my $self = shift;
##    my %cmd = validate( @_, {
##        help_text => { type => Params::Validate::SCALAR },  #required
##        usage     => { type => Params::Validate::SCALAR },  #required
##        topic     => { optional => 1, type => Params::Validate::SCALAR },
##        name      => { type => Params::Validate::SCALAR },  #required
##        command   => { type => ( Params::Validate::SCALAR | Params::Validate::CODEREF ) }, #required
##        context	  => { optional => 1, type => Params::Validate::ARRAYREF },
##        style     => { optional => 1, type => Params::Validate::SCALAR },
##        start     => { optional => 1, type => Params::Validate::CODEREF },
##        handler   => { optional => 1, type => Params::Validate::SCALAR },
##        stop      => { optional => 1, type => Params::Validate::CODEREF },
##    } );
#
#	my %cmdhash = (
#		'name'		=> $name[$$self],
#        'help'		=> $help[$$self],
#        'usage'		=> $usage[$$self],
#        'command' 	=> $command[$$self],
#	);
#	$cmdhash{'topic'} 	= $topic[$$self] 	if (defined($topic[$$self]));
#	$cmdhash{'contexts'}	= $contexts[$$self] if (defined($contexts[$$self]));
#	$cmdhash{'call_style'}	= $call_style[$$self] if (defined($call_style[$$self]));
#	$cmdhash{'handler'}	= $handler[$$self] 	if (defined($handler[$$self]));
#	$cmdhash{'start'}	= $start[$$self] 	if (defined($start[$$self]));
#	$cmdhash{'stop'}	= $stop[$$self] 	if (defined($stop[$$self]));
#
#  	return ( \%cmdhash );
#}

=item GetoptLucid( $kernel, $request)

Returns an option hash keyed on parameter after the arguments have bee parsed
by Getopt::Lucid. Will respond itself if there is an error and return nothing.

Takes the POE Kernel and the request as args.

=cut

sub GetoptLucid {
	my ($self, $kernel, $request, $package) = @_;

	my (@options, $func);

	# Creat an array for Getopt::Lucid
	foreach my $param ( values %{ $self->parameters }  )
	{
#		my $name = defined($param->aliases)
#			? $param->name.'|'.$param->aliases
#			: $param->name;
		my $name = $param->name;

		# don't put as required if default is set.
		if ( exists $self->required->{$name} &&
			( defined ($package) &&
			 not defined( $package->$name ) ) )
		{
			no strict 'refs';
			push(@options, $param->type->($param->Alias)->required() );
		}
		else
		{
			no strict 'refs';
			push(@options, $param->type->($param->Alias) );
		}
	}

	$self->Verbose("GetoptLucid: options ",2,\@options);

	my $opt;

#	$self->Verbose("GetoptLucid: request args",1,$request->args );

	# Parse the args using parameters.
	eval {$opt = Getopt::Lucid->getopt(
		\@options,
		$request->args,
		);
	};

	# If it went bad, error and return nothing.
	if( $@ )
	{
		$self->Verbose('GetoptLucid: got ('.$@.') ');
		$request->Respond($kernel,  "Invalid Args: $@ !", 400);
		return (0);
	}

	return( $opt );
}

=item Validate( <kernel>, <request>, <package> )

Returns a hash keyed on parameter after the arguments have been parsed
by Getopt::Lucid and validated by FormValidator::Simple as per the constraints
specified in the Parameter or Command definitions.
Will respond itself if there is an error and return nothing.

Takes the POE Kernel, the Request, and the Package as args.

=cut

sub Validate {
	my ($self, $kernel, $request, $package) = @_;

	# Getopt will send error if problem.
	return unless (my $opt  = $self->GetoptLucid($kernel, $request, $package) );

#	my %args = $opt->options;
	my %args = $self->ApplyDefaults($opt, $package, $request->input );

#	$self->Verbose("Validate: param",1,\%args);
#	$self->Verbose('Validate: $request->input ',1,$request->input);

	# are there any left?
	if (keys %args == 0 )
	{
		$self->Verbose('Validate: failed no valid args');
		$request->Respond($kernel,"No valid args found!", 400);
		return (0);
	}

	my (@profile, %input, $txt);

	# Creat an array for Form::Validator
	# and an %input without objects or things that aren't constrained
	foreach my $check ( values %{ $self->parameters }  )
	{
		if ( defined($check->constraints ) )
		{
			push(@profile, $check->name, $check->constraints );
			$input{ $check->name } = $args{ $check->name }
				if	(!ref( $args{ $check->name } ) );
		}
	}

	$self->Verbose("Validate: profile ",2,\@profile);

#	$self->Verbose("Validate: input",1,\%input);

	my $results = FormValidator::Simple->check( \%input => \@profile);

    if ( $results->has_error ) {
        foreach my $key ( @{ $results->error() } ) {
            foreach my $type ( @{ $results->error($key) } ) {
                $txt .= "Invalid: $key not $type \n";
                $txt .= "$key: ".$input{$key}." \n";
            }
        }
		$self->Verbose('Validate: failed ('.$txt.') ');
		$request->Respond($kernel,$txt, 400);
		return (0);
    }

	# create class objects if necessary
	my $param;
	foreach my $attr ( keys %args )
	{
		# args may not have all fields defined, gotta skip the empty ones.
		next unless (defined($args{$attr}) &&
			!( ($args{$attr} eq '' ) || ref( $args{$attr} ) )
			);

		$self->Verbose("Validate: attr($attr) => ".
			$args{$attr}." ",3);

		$param = $self->parameters->{ $attr };

		# is there a class object for this attr?
		if (defined( $param->class ) &&
			$param->class =~ /::/ )
		{
			my $class = $param->class;
			$self->Verbose("Validate: class($class) attr($attr) args{$attr}=>".$args{$attr},2);
			my $obj;
			eval {
				no strict 'refs';
				$obj = $class->new($args{$attr});
			};
			# If it went bad, error and return nothing.
			if( $@ )
			{
				$@ =~ qr(Usage:\s(.*)$)m ;
				$txt = $1;
				$self->Verbose('Validate: new '.$class.' got ('.$txt.') ');
				$request->Respond($kernel,  "Invalid: $attr !", 400);
				return;
			}
			$args{$attr} = $obj;
		}
	}

	$self->Verbose("Validate: returning args",2,\%args);

	return(\%args);
}

=item ApplyDefaults( <param_hash>, <package>, <input> )

Returns a hash keyed on parameter after the defaults from the Package
attributes have been applied. This is used during the Validate method.

=cut

sub ApplyDefaults {
	my ($self, $opt, $package, $input ) = @_;

	my %defaults;

	# Creat defaults hash for Getopt::Lucid
	foreach my $param ( values %{ $self->parameters }  )
	{
		# add to the default hash if an attribute exists in the package
		my $acc = $param->name;
		if (defined( $package ) &&
			$package->can( $acc ) &&
			defined( $package->$acc )
			)
		{
			$defaults{$acc} = $package->$acc;
		}
	}

	$self->Verbose("ApplyDefaults: defaults ",4,\%defaults);

	# turn results into a hash and return
	my %opt;

	# merge with defaults
	%opt = $opt->replace_defaults( %defaults );

#	$self->Verbose("ApplyDefaults: opt before cleansing ",1,\%opt);

	my $regex;
	# Hash has empty values for args not supplied. Take them out (again).
	foreach my $key ( keys %opt )
	{
		$regex = $self->parameters->{$key}->Alias;
		delete($opt{$key}) if (
			(not $opt{$key} ) &&        		# the value is blank or zero
			( $input !~ qr($regex) ||		# it was not in the input
			not ( defined( $package ) &&	# it is not defined in the defaults
			$package->can( $key ) &&
			defined( $package->$key ) ) )
			);
	}

	return( %opt );
}

=item BuildCommandLine( <param_hash>, <with_cmd> )

Returns a hash keyed on parameter after the arguments have been parsed
by Getopt::Lucid and validated by FormValidator::Simple as per the constraints
specified in the Parameter or Command definitions.
Will respond itself if there is an error and return nothing.

Takes the POE Kernel, the Request, and the Package as args.

=cut

sub BuildCommandLine {
	my ($self, $param_hash, $with_cmd ) = @_;

	my $command_line = $with_cmd ? $self->command." " : '';

	$command_line .= $self->cl_options." " if defined($self->cl_options);

	foreach my $param (sort keys %{$param_hash} )
	{
		my $cp = $self->parameters->{$param}->BuildCommandParam($param_hash)
			if ( defined($self->parameters->{$param} ) );
		# We'll get a empty string for nothing to set, don't add extra space.
		$command_line .= $cp." " if ($cp);
	}

	chop($command_line);
	$self->Verbose("BuildCommandLine: cl($command_line) ",2);
	return ($command_line);
}

1;
#__END__

=back

=head3 INHERITED METHODS

This module is an Object::InsideOut object that inherits from Agent::TCLI::Base. It
inherits methods from both. Please refer to their documentation for more
details.

=head1 AUTHOR

Eric Hacker	 E<lt>hacker at cpan.orgE<gt>

=head1 BUGS

When naming commands in the preinit commands hash or loading from loadyaml()
it is easy to accidentally
duplicate names and cause commands not to load. The author expects that when he
makes this a habit, he'll try to fix it by doing something better than a loading
a hash with no validation.

Most command packages process args in an eval statement which will sometimes
return rather gnarly detailed traces back to the user. This is not a security issue
because open source software is not a black box where such obscurity might
be relied upon (albeit ineffectively), but it is a bug.

SHOULDS and MUSTS are currently not always enforced.

Test scripts not thorough enough.

Probably many others.

=head1 LICENSE

Copyright (c) 2007, Alcatel Lucent, All rights resevred.

This package is free software; you may redistribute it
and/or modify it under the same terms as Perl itself.

=cut
