
package Config::Hierarchical ;
use base Exporter ;

use strict;
use warnings ;

BEGIN 
{
use Exporter ();

use vars qw ($VERSION @ISA @EXPORT_OK %EXPORT_TAGS);

$VERSION     = '0.13' ;
@EXPORT_OK   = qw ();
%EXPORT_TAGS = ();
}

#-------------------------------------------------------------------------------

use Carp ;
use Data::Compare;
use Sub::Install;

use English qw( -no_match_vars ) ;

use Readonly ;
Readonly my $EMPTY_STRING => q{} ;

Readonly my $VALID_OPTIONS =>
	{ 
	map{$_ => 1}
		qw(
			NAME VALUE 
			EVAL EVALUATOR
			HISTORY ATTRIBUTE
			COMMENT
			CATEGORY CATEGORIES_TO_EXTRACT_FROM 
			GET_CATEGORY WARN_FOR_EXPLICIT_CATEGORY
			SET_VALIDATOR
			VALIDATORS
			CHECK_LOWER_LEVEL_CATEGORIES
			LOCK FORCE_LOCK
			OVERRIDE
			SILENT_NOT_EXISTS SILENT_OVERRIDE
			DIE_NOT_EXISTS
			VERBOSE
			FILE LINE 
			ALIAS_CATEGORY
			DATA_TREEDUMPER_OPTIONS
			)
	} ;

Readonly my $CONSTRUCTOR_VALID_OPTIONS =>
	{ 
	map{$_ => 1}
		qw(
			LOG_ACCESS
			INITIAL_VALUES
			CATEGORY_NAMES
			DEFAULT_CATEGORY
			INTERACTION
			DISABLE_SILENT_OPTIONS
			LOCKED_CATEGORIES
			GET_CATEGORIES
			)
	} ;

#-------------------------------------------------------------------------------

=head1 NAME

 Config::Hierarchical - Hierarchical configuration container

=head1 SYNOPSIS

  use Config::Hierarchical ;
   
  my $config = new Config::Hierarchical(); 
  
  # or
  
  my $config = new Config::Hierarchical
			(
			NAME                       => 'some_namespace',
			VERBOSE                    => 0,
			DISABLE_SILENT_OPTIONS     => 0,
			CATEGORY_NAMES             => ['<CLI>', '<PBS>', 'PARENT', 'LOCAL', 'CURRENT'],
			DEFAULT_CATEGORY           => 'CURRENT',
			
			WARN_FOR_EXPLICIT_CATEGORY => 0,
			
			GET_CATEGORIES => 
				{
				Inheritable => ['CLI', 'PBS', 'PARENT', 'CURRENT'],
				},
				
			INTERACTION =>
				{
				INFO  => \&sub,
				WARN  => \&sub,
				DIE   => \&sub,
				DEBUG => \&sub,
				},
				
			SET_VALIDATOR => \&my_set_validator,
			
			VALIDATORS =>
				[
				{
				CATEGORY_NAMES => ['CLI', 'CURRENT',] ,
				NAMES          => ['CC', 'LD'],
				VALIDATORS     => 
					{
					alphanumeric => \&alphanumeric,
					other_validator => \&other_validator,
					},
				},
				
				{
				CATEGORY_NAMES => ['CURRENT',] ,
				NAMES          => ['CC',],
				VALIDATORS     => {only_gcc => \&only_gcc,},
				}, 
				],
				
			INITIAL_VALUES =>
				[
				{
				CATEGORY       => 'PBS',
				ALIAS_CATEGORY => $pbs_config,
				HISTORY        => ....,
				COMMENT        => ....,
				},
				
				{CATEGORY => 'CLI', NAME => 'CC', VALUE => 1,},
				{CATEGORY => 'CLI', NAME => 'LD', VALUE => 2, LOCK => 1},
				
				{CATEGORY => 'CURRENT', NAME => 'CC', VALUE => 3, OVERRIDE => 1},
				{CATEGORY => 'CURRENT', NAME => 'AS', VALUE => 4,},
				{CATEGORY => 'CURRENT', NAME => 'VARIABLE_WITH_HISTORY', VALUE => $previous_value, HISTORY => $history },
				] ,
				
			LOCKED_CATEGORIES => ['CLI'],
			) ;
	
  $config->Set(NAME => 'CC', VALUE => 'gcc') ;
  $config->Set(NAME => 'CC', VALUE => 'gcc', CATEGORY => 'CLI') ;
  $config->Set(NAME => 'CC', VALUE => 'gcc', FORCE_LOCK => 1) ;
  $config->Set(NAME => 'CC', VALUE => 'gcc', SILENT_OVERRIDE => 1, COMMENT => 'we prefer gcc') ;
  
  $config->Exists(NAME => 'CC') ;
  
  $config->GetKeyValueTuples() ;
  
  $config->SetMultiple
	(
	{FORCE_LOCK => 1}
	{NAME => 'CC', VALUE => 'gcc', SILENT_OVERRIDE => 1},
	{NAME => 'LD', VALUE => 'ld'},
	) ;
  
  $config->Set(CC => 'gcc') ;
  
  $value = $config->Get(NAME => 'CC') ;
  $value = $config->Get(NAME => 'NON_EXISTANT', SILENT_NOT_EXISTS => 1) ;
  
  @values = $config->GetMultiple(@config_variables_names) ;
  @values = $config->GetMultiple({SILENT_NOT_EXISTS => 1}, @config_variables_names) ;
  
  $hash_ref = $config->GetHashRef() ; # no warnings
  
  $config->GetInheritable() ;
  
  $config->SetDisableSilentOptions(1) ;
	
  $config->LockCategories('PBS') ;
  $config->UnlockCategories('CLI', 'PBS') ;
  $config->IsCategoryLocked('PBS') ;
  
  $config->Lock(NAME => 'CC') ;
  $config->Unlock(NAME => 'CC', CATEGORY => 'CLI') ;
  $config->IsLocked(NAME => 'CC') ;
  
  $history = $config->GetHistory(NAME => 'CC') ;
  $dump = $config->GetDump() ;
  

=head1 DESCRIPTION

This module implements a configuration variable container. The container has multiple categories which are 
declared in decreasing priority order.

A variable can exist in multiple categories within the container. When queried for a variable, the container
will return the variable in the category with the highest priority.

When setting a variable, the container will display a warning message if it is set in a category with lower priority
than a category already containing the same variable.

Priority overriding is also possible.

=head1 DOCUMENTATION

I'll start by giving a usage example. In a build system, configuration variables can have different source.

=over 2

=item * the build tool

=item * the command line

=item * the parent build file (in a hierarchical build system)

=item * the current build file

=back

It is likely that a configuration variable set on the command line should be used regardless of a local
setting. Also, a configuration variable set by the build tool itself should have the highest priority.

Among the most difficult errors to find are configuration errors in complex build systems. Build tools
generally don't help much when variables are overridden. it's also difficult to get a variable's history.

This module provides the necessary functionality to handle most of the cases needed in a modern build system.

Test t/099_cookbook.t is also a cookbook you can generate with POD::Tested. It's a nice complement to this 
documentation.

=head1 SUBROUTINES/METHODS

Subroutines that are not part of the public interface are marked with [p].

=cut

#-------------------------------------------------------------------------------

sub new
{

=head2 new(@named_arguments)

Create a Config::Hierarchical .  

  my $config = new Config::Hierarchical() ;

I<Arguments>

The arguments are named. All argument are optional. The order is not important.

  my $config = new Config::Hierarchical(NAME => 'some_namespace', VERBOSE  => 1) ;

=over 2

=item *	NAME

A string that will be used in all the dumps and interaction with the user.

=item *	CATEGORY_NAMES

A list of category names. The first named category has the highest priority.
Only categories listed in this list can be manipulated. Using an unregistered
category in a C<Set> or C<Get> operation will generate an error.

  my $config = new Config::Hierarchical
			(
			CATEGORY_NAMES   => ['CLI', '<PBS>', 'PARENT', 'CURRENT', 'LOCAL'],	
			DEFAULT_CATEGORY => 'CURRENT',
			) ;

A category can be B<protected> by enclosing its name in angle bracket, IE: B<<PBS>>. Protected 
categories will not be overridden by lesser priority categories even if the OVERRIDE option is used.

If no category names are given, B<'CURRENT'> will be used and B<DEFAULT_CATEGORY> will
be set accordingly.

=item * DEFAULT_CATEGORY

The name of the category used when C<Set> is called without a I<CATEGORY> argument.

If the B<CATEGORY_NAMES> list contains more than one entry, B<DEFAULT_CATEGORY> must be set or
an error will be generated.

=item * DIE_NOT_EXISTS

  my $config = new Config::Hierarchical(..., DIE_NOT_EXISTS => 0) ;

Calling L<Get> on an unexisting variable will generate an exception when this option is set. The option
is not set by default.

=item * DISABLE_SILENT_OPTIONS

  my $config = new Config::Hierarchical(NAME => 'some_namespace', DISABLE_SILENT_OPTIONS => 1) ;

When this option is set, B<SILENT_OVERRIDE> and B<SILENT_NOT_EXISTS> will be ignored and
B<Config::Hierarchical> will display a warning.

=item * GET_CATEGORIES 

This option allows you to define functions that fetch variables in a specific category
list and in a specific order.

  my $config = new Config::Hierarchical
			(
			CATEGORY_NAMES   => ['CLI', '<PBS>', 'PARENT', 'CURRENT', 'LOCAL'],
			
			GET_CATEGORIES =>
				{
				Inheritable => ['CLI', 'PBS', 'PARENT', 'CURRENT'],
				}
			...
			) ;
			
  my $value = $config->GetInheritable(NAME => 'CC') ;
  my $hash_ref = $config->GetInheritableHashRef() ;
  

In the example above, the B<LOCAL> category will not be used by B<GetInheritable>.

=item * WARN_FOR_EXPLICIT_CATEGORY

if set, B<Config::Hierarchical> will display a warning if any category is specified in C<Get> or C<Set>.

=item * VERBOSE

This module will display information about its actions when this option is set.

See B<INTERACTION> and C<SetDisplayExplicitCategoryWarningOption>.

=item * INTERACTION

Lets you define subs used to interact with the user.

  my $config = new Config::Hierarchical
			(
			INTERACTION      =>
				{
				INFO  => \&sub,
				WARN  => \&sub,
				DIE   => \&sub,
				DEBUG => \&sub,
				}
			) ;

=over 4

=item INFO

This sub will be used when displaying B<verbose> information.

=item WARN

This sub will be used when a warning is displayed. e.g. a configuration that is refused or an override.

=item DIE

Used when an error occurs. E.g. a locked variable is set.

=item DEBUG

If this option is set, Config::Hierarchical will call the sub before and after acting on the configuration.
This can act as a breakpoint in a debugger or allows you to pinpoint a configuration problem.

=back

The functions default to:

=over 2

=item * INFO => CORE::print

=item * WARN => Carp::carp

=item * DIE => Carp::confess

=back

=item * FILE and LINE

These will be used in the information message and the history information if set. If not set, the values
returned by I<caller> will be used. These options allow you to write wrapper functions that report the
callers location properly.

=item * INITIAL_VALUES

Lets you initialize the Config::Hierarchical object. Each entry will be passed to C<Set>.

  my $config = new Config::Hierarchical
			(
			...
			
			EVALUATOR => \&sub,
			
			INITIAL_VALUES =>
				[
				{ # aliased category
				CATEGORY       => 'PBS',
				ALIAS_CATEGORY => $pbs_config,
				HISTORY        => ....,
				COMMENT        => ....,
				},
				
				{CATEGORY => 'CLI', NAME => 'CC', VALUE => 1},
				{CATEGORY => 'CLI', NAME => 'LD', VALUE => 2, LOCK => 1},
				
				{CATEGORY => 'CURRENT', NAME => 'CC', VALUE => 3, OVERRIDE => 1},
				{CATEGORY => 'CURRENT', NAME => 'AS', VALUE => 4,},
				} ,
			) ;

See C<Set> for options to B<INITIAL_VALUES> and a details explanation about B<EVALUATOR>.

B<Aliased categories> allow you to use a category to refer to  an existing Config::Hierarchical object. 
The referenced object is read only. This is because multiple configurations might alias to the same 
B<Config::Hierarchical> object.

Variables from aliased category can still be overridden.

=item *  LOG_ACCESS

If this set, B<Config::Hierarchical> will log all access made through C<Get>.

=item * LOCKED_CATEGORIES

Lets you lock categories making them read only. Values in B<INITIAL_VALUES> are used before locking
the category.

  my $config = new Config::Hierarchical(..., LOCKED_CATEGORIES => ['CLI', 'PBS']) ;

See C<LockCategories> and C<IsCategoryLocked>.

=item * SET_VALIDATOR

This gives you full control over what gets into the config. Pass a sub reference that will be used to check
the configuration variable passed to the subroutine C<Set>.

Argument passed to the subroutine reference:

=over 4

=item $config

The configuration object. Yous should use the objects interaction subs for message display.

=item $options

The options passed to C<Set>.

=item $location

The location where C<Set> was called. Useful when displaying an error message.

=back

	sub my_set_validator
	{
	my ($config, $options, $location) = @_ ;
	
	# eg, check the variable name
	if($options->{NAME} !~ /^CFG_[A-Z]+/)
		{
		$config->{INTERACTION}{DIE}->("$config->{NAME}: Invalid variable name '$options->{NAME}' at at '$location'!")
		}
		
	# all OK, let Config::Hierarchical handle variable setting
	}
	
	my $config = new Config::Hierarchical(SET_VALIDATOR => \&my_set_validator) ;

=item * VALIDATORS

  my $config = new Config::Hierarchical
			(
			...
			VALIDATORS =>
				[
				{
				CATEGORY_NAMES => ['CURRENT', 'OTHER'] ,
				NAMES          => ['CC', 'LD'],
				VALIDATORS     => 
					{
					validator_name => \&PositiveValueValidator,
					other_validator => \&SecondValidator
					},
				},
				],
			) ;

Let you add validation subs to B<Config::Hierarchical> for specific variables.

Each variable in I<NAMES> in each category in I<CATEGORY_NAMES> will be assigned the validators 
defined in I<Validators>.

The example above will add a validator I<PositiveValueValidator> and validator I<SecondValidator> to
B<CURRENT::CC>, B<CURRENT::LD>, B<OTHER::CC> and B<OTHER::LD>.

A validator is sub that will be called every time a value is assigned to a variable. The sub is passed a single argument, the 
value to be assigned to the variable. If false is returned by any of the validators, an Exception will be raised through 
B<INTERACTION::DIE>.

see C<AddValidator>.

=back

=cut

my ($invocant, @setup_data) = @_ ;

my $class = ref($invocant) || $invocant ;

confess 'Invalid constructor call!' unless defined $class ;

my $self = {} ;

my ($package, $file_name, $line) = caller() ;
bless $self, $class ;

$self->Setup($package, $file_name, $line, @setup_data) ;

return($self) ;
}

#-------------------------------------------------------------------------------

sub GetInformation
{

=head2 GetInformation()

I<Arguments> - None

I<Returns> 

=over 2

=item * The configuration name

=item * The configuration object's creation location

=back

=cut

my ($self) = @_ ;

return($self->{NAME}, "$self->{FILE}:$self->{LINE}") ;
}

#-------------------------------------------------------------------------------

sub Setup
{

=head2 [p] Setup

Helper sub called by new. This shall not be used directly.

=cut

my ($self, $package, $file_name, $line, @setup_data) = @_ ;

SetInteractionDefault($self) ;
$self->CheckOptionNames
	(
	{ %{$VALID_OPTIONS}, %{$CONSTRUCTOR_VALID_OPTIONS}}, 
	@setup_data,
	NAME => 'Anonymous eval context', FILE => $file_name, LINE => $line,
	) ;

%{$self} = 
	(
	NAME                   => 'Anonymous',
	CATEGORY_NAMES         => ['CURRENT'],
	DISABLE_SILENT_OPTIONS => 0,
	FILE                   => $file_name,
	LINE                   => $line,
	
	@setup_data,
	
	CATEGORIES             => {},
	TIME_STAMP             => 0,
	) ;

SetInteractionDefault($self) ;

my $location = "$self->{FILE}:$self->{LINE}" ;

if($self->{VERBOSE})
	{
	$self->{INTERACTION}{INFO}('Creating ' . ref($self) . " '$self->{NAME}' at $location.\n") ;
	}

$self->SetupCategories($location) ;

if(exists $self->{VALIDATORS})
	{
	$self->AddValidators($self->{VALIDATORS}, $location) ;
	delete $self->{VALIDATORS} ;
	}

if(exists $self->{SET_VALIDATOR})
	{
	if('CODE' ne ref $self->{SET_VALIDATOR})
		{
		$self->{INTERACTION}{DIE}->("$self->{NAME}: Invalid 'SET_VALIDATOR' definition, expecting a sub reference at '$location'!") ;
		}
	}

if(exists $self->{EVALUATOR})
	{
	if('CODE' ne ref $self->{EVALUATOR})
		{
		$self->{INTERACTION}{DIE}->("$self->{NAME}: Invalid 'EVALUATOR' definition, expecting a sub reference at '$location'!") ;
		}
	}

# temporarely remove the locked categories till we have handled INITIAL_VALUES
my $category_locks ;

if(exists $self->{LOCKED_CATEGORIES})
	{
	if('ARRAY' ne ref $self->{LOCKED_CATEGORIES})
		{
		$self->{INTERACTION}{DIE}->("$self->{NAME}: Invalid 'LOCKED_CATEGORIES' at '$location'!") ;
		}
		
	$category_locks = $self->{LOCKED_CATEGORIES}  ;
	delete $self->{LOCKED_CATEGORIES} ;
	}
	
if(exists $self->{INITIAL_VALUES})
	{
	for my $element_data (@{$self->{INITIAL_VALUES}})
		{
		if(exists $element_data->{ALIAS_CATEGORY})
			{
			$self->SetCategoryAlias(FILE => $self->{FILE}, LINE => $self->{LINE}, %{$element_data}) ;
			}
		else
			{
			$self->Set(FILE => $self->{FILE}, LINE => $self->{LINE}, %{$element_data}) ;
			}
		}
		
	delete $self->{INITIAL_VALUES} ;
	
	if(defined $category_locks)
		{
		#TODO:  should be a category attribute not a config attribute
		$self->{LOCKED_CATEGORIES}  = { map {$_ => 1} @{$category_locks} } ;
		}
	}
	
CreateCustomGetFunctions(keys %{ $self->{GET_CATEGORIES} }) if exists $self->{GET_CATEGORIES} ;

return(1) ;
}

#-------------------------------------------------------------------------------

sub SetInteractionDefault
{
	
=head2 [p] SetInteractionDefault

Sets {INTERACTION} fields that are not set by the user.

=cut

my ($interaction_container) = @_ ;

$interaction_container->{INTERACTION}{INFO} ||= sub {print @_} ;  ## no critic (InputOutput::RequireCheckedSyscalls)
$interaction_container->{INTERACTION}{WARN} ||= \&Carp::carp ;
$interaction_container->{INTERACTION}{DIE}  ||= \&Carp::confess ;

return ;
}

#-------------------------------------------------------------------------------

sub SetupCategories
{

=head2 [p] SetupCategories

Helper sub called by new.

=cut

my ($self, $location) = @_ ;

# find the protected categories and removes the brackets from the name
$self->{PROTECTED_CATEGORIES} = { map{ if(/^<(.*)>$/sxm) {$1 => 1} else {} } @{ $self->{CATEGORY_NAMES} } } ;  ## no critic (BuiltinFunctions::ProhibitComplexMappings)

my @seen_categories ;
for my $name (@{$self->{CATEGORY_NAMES}})
	{
	if($name =~ /^<(.*)>$/sxm)
		{
		my $name_without_brackets = $1 ;
		
		if($name_without_brackets =~ /<|>/sxm)
			{
			$self->{INTERACTION}{DIE}->("$self->{NAME}: Invalid category name '$name_without_brackets' at '$location'!") ;
			}
		else
			{
			$name = $1 ;
			}
		}
		
	# create a list of higher level categories to avoid computing it at run time
	$self->{REVERSED_HIGHER_LEVEL_CATEGORIES}{$name} = [reverse @seen_categories] ;
	push @seen_categories, $name ;
	}

$self->{VALID_CATEGORIES} = { map{$_ => 1} @{$self->{CATEGORY_NAMES}}} ;

# set and check the default category
if(1 == @{$self->{CATEGORY_NAMES}})
	{
	$self->{DEFAULT_CATEGORY} = @{$self->{CATEGORY_NAMES}}[0] ;
	}
else
	{
	$self->{INTERACTION}{DIE}->("$self->{NAME}: No default category at '$location'!") unless exists $self->{DEFAULT_CATEGORY} ;
	}

unless(exists $self->{VALID_CATEGORIES}{$self->{DEFAULT_CATEGORY}})
	{
	$self->{INTERACTION}{DIE}->("$self->{NAME}: Invalid default category '$self->{DEFAULT_CATEGORY}' at '$location'!") ;
	}
	
return(1) ;
}

#-------------------------------------------------------------------------------

sub AddValidator
{
	
=head2  AddValidator(CATEGORY_NAMES => \@categories,	NAMES => \@names, VALIDATORS => \%validators)

	$config->AddValidator
			(
			CATEGORY_NAMES => ['CLI'] ,
			NAMES          => ['CC', 'LD'],
			VALIDATORS     => {positive_value => \&PositiveValueValidator},
			) ;

You can add validators after creating a configuration and even after adding variables to your configuration. The
existing variables will be checked when the validators are added.

I<Arguments>

=over 2

=item * CATEGORY_NAMES => \@catagories - A reference to an array containing the names of the categories to add the validators to

=item * NAMES => \@names - A reference to an array containing the names of the variables that will be validated

=item * VALIDATORS => \%validators - A reference to a hash where keys are validator_names and values are validator code references

=back

I<Returns> - Nothing

B<Config::Hierarchical> will warn you if you override a validator.

=cut

my ($self,  %setup) = @_ ;

my ($package, $file_name, $line) = caller() ;
my $location = "$self->{FILE}:$self->{LINE}" ;

$self->AddValidators([{%setup}], $location) ;

return(1) ;
}

#-------------------------------------------------------------------------------

Readonly my $EXPECTED_NUMBER_OF_ARGUMENTS_FOR_ADD_VALIDATOR => 3 ;

sub AddValidators
{
	
=head2 [p] AddValidators

=cut

my ($self,  $validators, $location) = @_ ;

for my $validator_definition (@{$validators})
	{
	if
		(
		'HASH' ne ref $validator_definition
		||  $EXPECTED_NUMBER_OF_ARGUMENTS_FOR_ADD_VALIDATOR != keys %{$validator_definition}
		
		|| ! exists $validator_definition->{CATEGORY_NAMES}
		|| 'ARRAY' ne ref $validator_definition->{CATEGORY_NAMES}
		
		|| ! exists $validator_definition->{NAMES}
		|| 'ARRAY' ne ref $validator_definition->{NAMES}
		
		|| ! exists $validator_definition->{VALIDATORS}
		|| 'HASH' ne ref $validator_definition->{VALIDATORS}
		)
		{
		$self->{INTERACTION}{DIE}->("$self->{NAME}: Invalid validator definition at '$location'!")  ;
		}
		
	for my $category_name (@{$validator_definition->{CATEGORY_NAMES}})
		{
		unless(exists $self->{VALID_CATEGORIES}{$category_name})
			{
			$self->{INTERACTION}{DIE}->("$self->{NAME}: Invalid category '$category_name' in validator setup at '$location'!") ;
			}
			
		for my $variable_name (@{$validator_definition->{NAMES}})
			{
			$self->AddVariableValidator($category_name, $variable_name, $validator_definition, $location) ;
			}
		}
	}
	
return(1) ;
}

#-------------------------------------------------------------------------------

sub AddVariableValidator
{
	
=head2 [p] AddVariableValidator


=cut

my ($self, $category_name, $variable_name, $validator_definition, $location) = @_ ;

for my $validator (keys %{$validator_definition->{VALIDATORS}})
	{
	my ($config_variable_value_exists, $config_variable_value) ;

	if(exists $self->{ALIASED_CATEGORIES}{$category_name})
		{
		$self->{INTERACTION}{DIE}->("$self->{NAME}: Can't Add validator '$validator' to aliased category '${category_name}'at '$location'.\n") ;
		}
		
	if($self->{VERBOSE})
		{
		$self->{INTERACTION}{INFO}->("$self->{NAME}: Adding validator '$validator' defined at '$location' to '${category_name}::$variable_name'.\n") ;
		}
		
	if(exists $self->{CATEGORIES}{$category_name}{$variable_name})
		{
		if(exists $self->{CATEGORIES}{$category_name}{$variable_name}{VALUE})
			{
			$config_variable_value_exists++ ;
			$config_variable_value = $self->{CATEGORIES}{$category_name}{$variable_name}{VALUE} ;
			}
		}
	else
		{
		$self->{CATEGORIES}{$category_name}{$variable_name} = {} ;
		}

	my $config_variable = $self->{CATEGORIES}{$category_name}{$variable_name} ;

	if('CODE' ne ref $validator_definition->{VALIDATORS}{$validator})
		{
		$self->{INTERACTION}{DIE}->("$self->{NAME}: Invalid validator '$validator' (must be a code reference) at '$location'!") ;
		}
		
	if(exists $config_variable->{VALIDATORS}{$validator})
		{
		$self->{INTERACTION}{WARN}->
			(
			  "$self->{NAME}: Overriding variable '$variable_name' validator '$validator' "
			. '(originaly defined at ' . $config_variable->{VALIDATORS}{$validator}{ORIGIN} . ') '
			. "at '$location'!"
			) ;
		}
		
	$config_variable->{VALIDATORS}{$validator}{ORIGIN} = $location ;
	$config_variable->{VALIDATORS}{$validator}{SUB} = $validator_definition->{VALIDATORS}{$validator} ;

	if($config_variable_value_exists)
		{
		# check already existing value
		
		unless($validator_definition->{VALIDATORS}{$validator}->($config_variable_value))
			{
			$self->{INTERACTION}{DIE}->
				("$self->{NAME}: Invalid value '$config_variable_value' for variable '$variable_name'. Validator '$validator' defined at '$location'.\n") ;
			}
		}
	}

return(1) ;
}

#-------------------------------------------------------------------------------

sub SetCategoryAlias
{
	
=head2 [p] SetCategoryAlias

Used to handle category aliases.

  my $pbs_config = new Config::Hierarchical(...) ;
  
  my $config = new Config::Hierarchical
			(
			NAME                       => 'some_namespace',
			CATEGORY_NAMES             => ['<CLI>', '<PBS>', 'PARENT', 'LOCAL', 'CURRENT'],
				
			INITIAL_VALUES =>
				[
				{
				CATEGORY       => 'PBS',
				ALIAS_CATEGORY => $pbs_config,
				HISTORY        => ....,
				COMMENT        => ....,
				},
				{NAME => 'CC1', VALUE => 'gcc'},
				...
				] ,
				
			) ;

B<CATEGORY> and B<ALIAS_CATEGORY> must be passed as arguments. See C<new> for details about aliased categories.

I<Arguments>

=over 2

=item * HISTORY

=item * COMMENT

=item * CHECK_LOWER_LEVEL_CATEGORIES 

=back

=cut

my ($self, @options) = @_ ;

$self->CheckOptionNames($VALID_OPTIONS, @options) ;

my %options = @options ;

my $location = "$options{FILE}:$options{LINE}" ;
my $category = $options{CATEGORY} ;

$self->{INTERACTION}{DIE}->("$self->{NAME}: Invalid category '$category' at at '$location'!") unless exists $self->{VALID_CATEGORIES}{$options{CATEGORY}} ;
$self->{INTERACTION}{DIE}->("$self->{NAME}: Invalid 'NAME' at '$location'!") if defined $options{NAME} ;
$self->{INTERACTION}{DIE}->("$self->{NAME}: Invalid 'VALUE' at '$location'!") if defined $options{VALUE} ;

# category must not have been set or aliased
if(exists $self->{CATEGORIES}{$category})
	{
	$self->{INTERACTION}{DIE}->("$self->{NAME}: Can't alias a category that's is already set at '$location'!") ;
	}

# inform of action if option set
if($self->{VERBOSE})
	{
	$self->{INTERACTION}{INFO}->("$self->{NAME}: SetCategoryAlias called for category '$category' at '$location'.\n") ;
	}

use Config::Hierarchical::Tie::ReadOnly ;

my %alias_hash ;
tie %alias_hash, 'Config::Hierarchical::Tie::ReadOnly', $options{ALIAS_CATEGORY} ; ## no critic (ProhibitTies)

# first check we can do this
for($options{ALIAS_CATEGORY}->GetKeyValueTuples())
	{
	$self->Set
			(
			CATEGORY => $category,
			NAME => $_->{NAME},
			VALUE => $_->{VALUE},
			CHECK_LOWER_LEVEL_CATEGORIES => $options{CHECK_LOWER_LEVEL_CATEGORIES},
			FILE => $options{FILE},
			LINE => $options{LINE},
			)	
	}

#override everything
$self->{CATEGORIES}{$category} = \%alias_hash ;

$self->{ALIASED_CATEGORIES}{$category} = {} ;
$self->{ALIASED_CATEGORIES}{$category}{COMMENT} =  $options{COMMENT} if exists $options{COMMENT} ;
$self->{ALIASED_CATEGORIES}{$category}{HISTORY} =  {TIME => $self->{TIME_STAMP}, EVENT => $options{HISTORY}} if exists $options{HISTORY} ;
$self->{ALIASED_CATEGORIES}{$category}{TIME_STAMP} =  $self->{TIME_STAMP}++ ;

$self->{LOCKED_CATEGORIES}{$category}++ ;

return(1) ;
}

#-------------------------------------------------------------------------------

sub CreateCustomGetFunctions
{
	
=head2 [p] CreateCustomGetFunctions

Creates custom B<Get*> functions.

=cut

my (@function_names) = @_ ;

for my $function_name (@function_names)
	{
	my $get_code = sub 
			{
			my($self, @arguments) = @_ ;
			
			return
				(
				$self->Get(@arguments, CATEGORIES_TO_EXTRACT_FROM => $self->{GET_CATEGORIES}{$function_name})
				) ;
			} ;
		
	Sub::Install::install_sub
		({
		code => $get_code,
		as   => 'Get' . $function_name
		});
		
	my $get_hash_ref_code = sub 
			{
			my($self, @arguments) = @_ ;
			
			return
				(
				$self->GetHashRef(CATEGORIES_TO_EXTRACT_FROM => $self->{GET_CATEGORIES}{$function_name})
				) ;
			} ;
		
	Sub::Install::install_sub
		({
		code => $get_hash_ref_code ,
		as   => 'Get' . $function_name . 'HashRef'
		});
	}

return(1) ;
}

#-------------------------------------------------------------------------------

sub CheckOptionNames
{

=head2 [p] CheckOptionNames

Verifies the options passed to the members of this class. Calls B<{INTERACTION}{DIE}> in case
of error. 

=cut

my ($self, $valid_options, @options) = @_ ;

if (@options % 2)
	{
	$self->{INTERACTION}{DIE}->('Invalid number of argument!') ;
	}

my %options = @options ;

for my $option_name (keys %options)
	{
	unless(exists $valid_options->{$option_name})
		{
		$self->{INTERACTION}{DIE}->("$self->{NAME}: Invalid Option '$option_name' at '$self->{FILE}:$self->{LINE}'!")  ;
		}
	}

if
	(
	   (defined $options{FILE} && ! defined $options{LINE})
	|| (!defined $options{FILE} && defined $options{LINE})
	)
	{
	$self->{INTERACTION}{DIE}->("$self->{NAME}: Incomplete option FILE::LINE!") ;
	}

return(1) ;
}

#-------------------------------------------------------------------------------

sub Set
{

=head2 Set(@named_arguments)

  my $config = new Config::Hierarchical() ;
  
  $config->Set(NAME => 'CC', VALUE => 'gcc') ;
  
  $config->Set
		(
		NAME => 'CC', VALUE => 'gcc',
		
		# options
		HISTORY         => $history,
		COMMENT         => 'we like gcc'
		CATEGORY        => 'CLI',
		VALIDATORS      => {positive_value => \&PositiveValueValidator,}
		FORCE_LOCK      => 1,
		LOCK            => 1,
		OVERRIDE        => 1,
		SILENT_OVERRIDE => 1,
		ATTRIBUTE       => 'some attribute',
		FILE            => 'some_file',
		LINE            => 1,
		
		CHECK_LOWER_LEVEL_CATEGORIES => 1,
		) ;

I<ARGUMENTS>

=over 2

=item * NAME - The variable's name. MANDATORY

=item * EVAL - Can be used instead for B<NAME>. See I<'Using EVAL instead for VALUE'>

=item * VALUE - A scalar value associated with the 'B<NAME>' variable. MANDATORY

=item * HISTORY

The argument passed is kept in the configuration variable. You can pass any scalar variable; B<Config::Hierarchical> will
not manipulate this information.

See C<GetHistory>.

=item * COMMENT

A comment that will be added to the variable history.

=item * CATEGORY

The name of the category where the variable resides. If no B<CATEGORY> is given, the default category is used.

=item * ATTRIBUTE 

Set the configuration variable's attribute to the passed argument.  See <SetAttribute>.

=item * SET_VALIDATOR

Configuration validators that will only be used during this call to B<Set>. The I<SET_VALIDATOR> set in the constructor
will not be called if this option is set. This lets you add configuration variable from different source and check them
with specialized validators.

=item * VALIDATORS

Extra validators that will only be used during this call to B<Set>.

=item * FORCE_LOCK

If a variable is locked, trying to set it will generate an error. It is possible to temporarily force
the lock with this option. A warning is displayed when a lock is forced.

=item * LOCK

Will lock the variable if set to 1, unlock if set to 0.

=item * OVERRIDE

This allows the variable in a category to override the variable in a category with higher priority. Once a variable
is overridden, it's value will always be the override value even if it is set again.

	my $config = new Config::Hierarchical
				(
				NAME => 'Test config',
				
	                        CATEGORY_NAMES         => ['PARENT', 'CURRENT'],
	                        DEFAULT_CATEGORY       => 'CURRENT',
						
				INITIAL_VALUES  =>
					[
					{NAME => 'CC', CATEGORY => 'PARENT', VALUE => 'parent'},
					] ,
				) ;
				
	$config->Set(NAME => 'CC', CATEGORY => 'CURRENT', OVERRIDE => 1, VALUE => 'current') ;
	$config->Set(NAME => 'CC', CATEGORY => 'PARENT', VALUE => 'parent') ;
	
	$config->Get(NAME => 'CC') ; # will return 'current'

=item * SILENT_OVERRIDE

Disables the warning displayed when overriding a variable.

=item * FILE and LINE

See B<FILE and LINE> in C<new>.

=item * CHECK_LOWER_LEVEL_CATEGORIES  

B<Config::Hierarchical> display warnings about all the collisions with higher priority
categories. If this option is set, warnings will also be displayed for lower priority categories.

=back

=head3 History

B<Config::Hierarchical> will keep a history of all the setting you make. The history can be retrieved with C<GetHistory>.
The history is also part of the dump generated by C<GetDump>.

=head3 Using B<EVAL> instead for B<VALUE>

Quite often configuration variables values are base on other configuration variable values. A typical example
would be a set of paths.

	my $config = new Config::Hierarchical() ;
	
	$config->Set(NAME => 'BASE',        VALUE => '/somewhere') ;
	$config->Set(NAME => 'MODULE',      VALUE => 'module') ;
	$config->Set(NAME => 'CONFIG_FILE', VALUE => 'my_config') ;

If you wanted to set a variable to the full path of your config file you have to write:

	$config->Set
		(
		NAME => 'PATH_TO_CONFIG_FILE', 
		VALUE => $config->Get(NAME => 'BASE') . '/'
			 . $config->Get(NAME => 'MODULE') . '/'
			 . $config->Get(NAME => 'CONFIG_FILE'),
		) ;

If you have many variables that are based on other variables, you code get messy quite fast.
With a little work, B<Config::Hierarchical> let's you write code like this:

	$config->Set(NAME => 'PATH_TO_CONFIG_FILE', EVAL => q~ "$BASE/$MODULE/$CONFIG_FILE" ~) ;

To achieve this, B<Config::Hierarchical> let's you implement an I<"EVALUATOR">, a subroutine 
responsible for handling B<EVAL>. It is set during the call to C<new> or C<Set>. The subroutine
is passed the following arguments:

=over 2

=item * $config - A reference to the B<Config::Hierarchical> object

=item * $arguments - A hash reference containing the arguments passed to C<Set>

=back

Below is an example using L<Eval::Context>. See I<t/020_eval.t> for a complete example.

  sub eval_engine
  {
  my ($config, $arguments) = @_ ;
  my $hash_ref = $config->GetHashRef() ;
  
  my $context = new Eval::Context
  		(
  		INSTALL_VARIABLES => 
  			[
  			map {["\$$_" => $hash_ref->{$_} ]} keys %$hash_ref
  			],
		INTERACTION  =>
			{
			EVAL_DIE => sub { my($self, $error) = @_ ; croak $error; },
			}
  		) ;
  
  my $value = eval {$context->eval(CODE => $arguments->{EVAL})} ;
  
  if($@)
  	{
  	$config->{INTERACTION}{DIE}->
  		(
  		"Error: Config::Hierarchical evaluating variable '$arguments->{NAME}' "
  		. "at $arguments->{FILE}:$arguments->{LINE}:\n\t". $@
  		) ;
  	}
  
  return $value ;
  }
  
  my $config = new Config::Hierarchical(EVALUATOR => \&eval_engine, ...) ;


B<EVAL> can be used in C<Set> and in B<INITIAL_VALUES>.

=cut

my ($self, @options) = @_ ;

$self->CheckOptionNames($VALID_OPTIONS, @options) ;

my %options = @options ;

unless(defined $options{FILE})
	{
	my ($package, $file_name, $line) = caller() ;
	
	$options{FILE} = $file_name ;
	$options{LINE} = $line ;
	}

my $location = "$options{FILE}:$options{LINE}" ;

if(exists $options{CATEGORY})
	{
	if($self->{WARN_FOR_EXPLICIT_CATEGORY})
		{
		$self->{INTERACTION}{WARN}->("$self->{NAME}: Setting '$options{NAME}' using explicit category at '$location'!\n") ;
		}
	}
else
	{
	$options{CATEGORY} = $self->{DEFAULT_CATEGORY} ;
	}

#~ use Data::TreeDumper ;
#~ print DumpTree {Options => \%options, Self => $self} ;

$self->CheckSetArguments(\%options, $location) ;

my $value_to_display = defined $options{VALUE} ? "'$options{VALUE}'" : 'undef' ;

# inform of action if option set
if($self->{VERBOSE})
	{
	$self->{INTERACTION}{INFO}->("$self->{NAME}: Setting '$options{CATEGORY}::$options{NAME}' to $value_to_display at '$location'.\n") ;
	}

# run debug hook if any
if(defined $self->{INTERACTION}{DEBUG})
	{
	$self->{INTERACTION}{DEBUG}->
		(
		"Setting '$options{CATEGORY}::$options{NAME}' to $value_to_display at '$location'.",
		$self,
		\%options,
		) ;
	}
	
if(exists $self->{LOCKED_CATEGORIES}{$options{CATEGORY}})
	{
	$self->{INTERACTION}{DIE}->("$self->{NAME}: Variable '$options{CATEGORY}::$options{NAME}', category '$options{CATEGORY}' was locked at '$location'.\n") ;
	}

if
	(
	      exists $self->{CATEGORIES}{$options{CATEGORY}}{$options{NAME}}
	&& defined $self->{CATEGORIES}{$options{CATEGORY}}{$options{NAME}}{OVERRIDE}
	&& ! exists $options{OVERRIDE}
	)
	{
	my $override_location = $self->{CATEGORIES}{$options{CATEGORY}}{$options{NAME}}{OVERRIDE} ;
	
	$self->{INTERACTION}{WARN}->("$self->{NAME}: '$options{NAME}' is of OVERRIDE type set at '$override_location' at '$location'!\n") ;
	$options{OVERRIDE} = '1 (due to previous override)' ;
	}
	
my ($high_priority_check_set_status, $high_priority_check_warnings) = $self->CheckHigherPriorityCategories(\%options, $location) ;
my ($low_priority_check_set_status, $low_priority_check_warnings) = ($EMPTY_STRING, $EMPTY_STRING) ;

if($self->{CHECK_LOWER_LEVEL_CATEGORIES} || $options{CHECK_LOWER_LEVEL_CATEGORIES})
	{
	($low_priority_check_set_status, $low_priority_check_warnings) = $self->CheckLowerPriorityCategories(\%options, $location) ;
	}

my $warnings = $high_priority_check_warnings . $low_priority_check_warnings ;
my $set_status = $high_priority_check_set_status . $low_priority_check_set_status ;

if($warnings ne $EMPTY_STRING)
	{
	$self->{INTERACTION}{WARN}->
		(
		"$self->{NAME}: Setting '$options{CATEGORY}::$options{NAME}' at '$location':\n$warnings" 
		) ;
	}

$self->CheckAndSetVariable(\%options, $set_status, $location) ;

return(1) ;
}

#-------------------------------------------------------------------------------

sub CheckSetArguments
{

=head2 [p] CheckSetArguments

Checks input to B<Set>.

=cut

my ($self, $options, $location) = @_ ;

$self->{INTERACTION}{DIE}->("$self->{NAME}: Invalid category '$options->{CATEGORY}' at at '$location'!") unless exists $self->{VALID_CATEGORIES}{$options->{CATEGORY}} ;
$self->{INTERACTION}{DIE}->("$self->{NAME}: Missing name at '$location'!") unless defined $options->{NAME} ;

if(exists $options->{VALUE} && exists $options->{EVAL})
	{
	$self->{INTERACTION}{DIE}->("$self->{NAME}: Can't have 'VALUE' and 'EVAL' at '$location'!") ;
	}

if(! exists $options->{VALUE} && ! exists $options->{EVAL})
	{
	$self->{INTERACTION}{DIE}->("$self->{NAME}: Missing 'VALUE' or 'EVAL' at '$location'!") ;
	}

if(exists $options->{EVAL})
	{
	if(exists $self->{EVALUATOR})
		{
		$options->{VALUE} = $self->{EVALUATOR}->($self, $options) ;
		}
	else
		{
		$self->{INTERACTION}{DIE}->("$self->{NAME}: No 'EVALUATOR' defined at '$location'!") ;
		}
	}

if(exists $options->{SET_VALIDATOR})
	{
	$options->{SET_VALIDATOR}->($self, $options, $location) 
	}
elsif(exists $self->{SET_VALIDATOR})
	{
	$self->{SET_VALIDATOR}->($self, $options, $location) ;
	}

if(exists $self->{ALIASED_CATEGORIES}{$options->{CATEGORY}})
	{
	$self->{INTERACTION}{DIE}->("$self->{NAME}: Can't set aliased category (read only) at '$location'!")  ;
	}
	
return(1) ;
}

#-------------------------------------------------------------------------------

sub CheckHigherPriorityCategories
{

=head2 [p] CheckHigherPriorityCategories

Check if a config variable setting overrides a higher priority category.

=cut

my ($self, $options, $location) = @_ ;

my (@reversed_higher_priority_categories) = @{$self->{REVERSED_HIGHER_LEVEL_CATEGORIES}{$options->{CATEGORY}}} ;

my ($warnings, $set_status) = ($EMPTY_STRING, $EMPTY_STRING) ;

my $crossed_protected_category = 0 ;

for my $category (@reversed_higher_priority_categories)
	{
	# categories are travesed in reverse order as it is not allowed to override across a protected category
	# check all higher priority categories and warn of override
	
	if((! $crossed_protected_category) && $options->{OVERRIDE})
		{
		if(exists $self->{PROTECTED_CATEGORIES}{$category})
			{
			my $message = "'<${category}>::$options->{NAME}' takes precedence." ;
			$set_status .=  $message ;
			
			my ($name_exists_in_category, $value_exists_in_category, $value_in_category) 
				= $self->CheckVariableInCategory($category, $options->{NAME}) ;
				
			if($name_exists_in_category && $value_exists_in_category)
				{
				if(!Compare($value_in_category, $options->{VALUE}))
					{
					$warnings   .= "\t$message\n" ;
					}
					
				last; # can't override over a protected category
				}
			else
				{
				$crossed_protected_category++ ; # keep looking for a category that can take precedence
				}
			}
		else
			{
			my ($override_set_status, $override_warnings)
				 = $self->OverrideVariable
					(
					$category,
					$options->{NAME},
					$options->{VALUE},
					$options->{CATEGORY},
					$location,
					$options->{SILENT_OVERRIDE}
					) ;
					
			$set_status .=	$override_set_status ;
			$warnings .= $override_warnings ;
			}
		}
	else
		{
		my $message = exists $self->{PROTECTED_CATEGORIES}{$category} ?
						"'<${category}>::$options->{NAME}' takes precedence ." :
						"'${category}::$options->{NAME}' takes precedence ." ;
		
		$set_status .=  $message ;
		
		my ($name_exists_in_category, $value_exists_in_category, $value_in_category) 
			= $self->CheckVariableInCategory($category, $options->{NAME}) ;
		
		if($name_exists_in_category && $value_exists_in_category)
			{
			if(!Compare($value_in_category, $options->{VALUE}))
				{
				$warnings   .= "\t$message\n" ;
				}
				
			last if(exists $self->{PROTECTED_CATEGORIES}{$category}) ;
			}
		}
	}

return($set_status, $warnings) ;
}

sub CheckVariableInCategory
{

=head2 [p] CheckVariableInCategory


=cut

my ($self, $category, $name) = @_ ;
my ($name_exists, $value_exists, $value, $overridden) ;

if(exists $self->{CATEGORIES}{$category} && exists $self->{CATEGORIES}{$category}{$name})
	{
	$name_exists++ ;
	
	if(exists $self->{ALIASED_CATEGORIES}{$category})
		{
		$value_exists = 1 ;
		$value = $self->{CATEGORIES}{$category}{$name} ;
		
		if(exists $self->{ALIASED_CATEGORIES}{$category}{$name}{OVERRIDDEN})
			{
			$overridden = $self->{ALIASED_CATEGORIES}{$category}{$name}{OVERRIDDEN}
			}
		}
	else
		{
		if(exists $self->{CATEGORIES}{$category}{$name}{VALUE})
			{
			$value_exists = 1 ;
			$value = $self->{CATEGORIES}{$category}{$name}{VALUE} ;
			
			if(exists $self->{CATEGORIES}{$category}{$name}{OVERRIDDEN})
				{
				$overridden = $self->{CATEGORIES}{$category}{$name}{OVERRIDDEN} ;
				}
			}
		}
	}

return ($name_exists, $value_exists, $value, $overridden)  ;
}

#-------------------------------------------------------------------------------

sub OverrideVariable ## no critic (Subroutines::ProhibitManyArgs)
{
	
=head2 [p] OverrideVariable


=cut

my ($self, $category, $variable_name, $value, $overriding_category, $location, $silent_override) = @_ ;

my ($set_status, $warnings) = ($EMPTY_STRING, $EMPTY_STRING) ;

my $override_message = "Overriding '${category}::$variable_name'" ;

my ($name_exists_in_category, $value_exists_in_category, $value_in_category) 
	= $self->CheckVariableInCategory($category, $variable_name) ;

if($name_exists_in_category && $value_exists_in_category)
	{
	if(!Compare($value_in_category, $value))
		{
		my $no_silent_override = (! ($silent_override || $self->{DISABLE_SILENT_OPTIONS})) ;
		
		$warnings   .= "\t$override_message\n" if($no_silent_override) ;
		$set_status .= "$override_message (existed, value was different)." ;
		}
	else
		{
		$set_status .= "$override_message (existed, value was equal)." ;
		}
	}
else
	{
	$set_status .= "$override_message (didn't exist)" ;
	}
	
#last to avoid autovivication
if(exists $self->{ALIASED_CATEGORIES}{$category})
	{
	# override localy, aliased config is not modified
	push @{ $self->{ALIASED_CATEGORIES}{$category}{$variable_name}{OVERRIDDEN} }, {CATEGORY => $overriding_category, AT => $location} ;
	}
else
	{
	push @{ $self->{CATEGORIES}{$category}{$variable_name}{OVERRIDDEN} }, {CATEGORY => $overriding_category, AT => $location} ;
	}

return($set_status, $warnings) ;
}

#-------------------------------------------------------------------------------

sub CheckLowerPriorityCategories
{

=head2 [p] CheckLowerPriorityCategories

Check if a config variable setting takes precedence over a lower priority category.

=cut

my ($self, $options, $location) = @_ ;

my ($warnings, $set_status, @lower_priority_categories) = ($EMPTY_STRING, $EMPTY_STRING) ;

for my $category (reverse @{$self->{CATEGORY_NAMES}})
	{
	if($category eq $options->{CATEGORY})
		{
		last ;
		}
	else
		{
		push @lower_priority_categories, $category ;
		}
	}
	
for my $category (reverse @lower_priority_categories)
	{
	my ($name_exists_in_category, $value_exists_in_category, $value_in_category) 
		= $self->CheckVariableInCategory($category, $options->{NAME}) ;
	
	if
		(
		   $name_exists_in_category 
		&& !Compare($value_in_category, $options->{VALUE})
		)
		{
		my $message = exists $self->{PROTECTED_CATEGORIES}{$category} ?
					"Takes Precedence over lower category '<${category}>::$options->{NAME}'" :
					"Takes Precedence over lower category '${category}::$options->{NAME}'" ;
			
		$set_status .=  $message ;
		$warnings   .= "\t$message\n" ;
		}
	}
	
return($set_status, $warnings) ;
}

#-------------------------------------------------------------------------------

sub CheckAndSetVariable
{ ## no critic (ProhibitExcessComplexity)

=head2 [p] CheckAndSetVariable

Set the variable in its category, verify lock, etc..

=cut

my($self, $options, $set_status, $location) = @_ ;

my $config_variable_exists = exists $self->{CATEGORIES}{$options->{CATEGORY}}{$options->{NAME}} ;

my $action = $EMPTY_STRING ;
my $config_variable ;

$self->Validate($options, $set_status, $location, $config_variable_exists)  ;

unless($config_variable_exists)
	{
	# didn't exist before this call
	
	$config_variable = $self->{CATEGORIES}{$options->{CATEGORY}}{$options->{NAME}} = {} ;

	$action .=  'CREATE' ;
	$action .=  exists $options->{HISTORY} ? ', SET HISTORY' : $EMPTY_STRING ;
	$action .=  exists $options->{ATTRIBUTE} ? ', SET ATTRIBUTE' : $EMPTY_STRING ;
	$action .= ' AND SET' ;
	
	$set_status .= 'OK.' ;
	}
else
	{
	$action = 'SET' ;
	$action .=  exists $options->{ATTRIBUTE} ? ', SET ATTRIBUTE' : $EMPTY_STRING ;

	if(exists $options->{HISTORY})
		{
		$self->{INTERACTION}{DIE}->("$self->{NAME}: Can't add history for already existing variable '$options->{CATEGORY}::$options->{NAME}' at '$location'.\n") ;
		}
		
	$config_variable = $self->{CATEGORIES}{$options->{CATEGORY}}{$options->{NAME}} ;
	 
	if(exists $config_variable->{OVERRIDDEN})
		{
		$self->{INTERACTION}{WARN}->("$self->{NAME}: Variable '$options->{CATEGORY}::$options->{NAME}' was overridden at '$config_variable->{OVERRIDDEN}'. The new value defined at '$location' might not be used.\n") ;
		}
		
	if(! Compare($config_variable->{VALUE}, $options->{VALUE}))
		{
		# not the same value
		
		unless(exists $config_variable->{LOCKED})
			{
			#~ Not locked, set
			$set_status .= 'OK.' ;
			}
		else
			{
			if($options->{FORCE_LOCK})
				{
				$set_status .= 'OK, forced lock.' ;
				$self->{INTERACTION}{WARN}->("$self->{NAME}: Forcing locked variable '$options->{CATEGORY}::$options->{NAME}' at '$location'.\n") ;
				}
			else 
				{
				$self->{INTERACTION}{DIE}->("$self->{NAME}: Variable '$options->{CATEGORY}::$options->{NAME}' was locked and couldn't be set at '$location'.\n") ;
				}
			}
		}
	else
		{
		$set_status .= 'OK, same value.' ;
		}
	}

$config_variable->{VALUE} = $options->{VALUE} ;
$config_variable->{OVERRIDE} = $location if $options->{OVERRIDE} ;
$config_variable->{ATTRIBUTE} = $options->{ATTRIBUTE} if $options->{ATTRIBUTE} ;

#~ set lock state
my $lock = $EMPTY_STRING ;
my $force_lock = $options->{FORCE_LOCK} ? 'FORCE_LOCK, ' : $EMPTY_STRING ;

if(exists $options->{LOCK})
	{
	if($options->{LOCK})
		{
		$lock = 'LOCK(1), ' ;
		$config_variable->{LOCKED} = $location  ;
		}
	else
		{
		$lock = 'LOCK(0), ' ;
		delete $config_variable->{LOCKED} ;
		}
	}
	
# update history

my $override = exists $options->{OVERRIDE} ? 'OVERRIDE, ' : $EMPTY_STRING ;

my $value_to_display = defined $options->{VALUE} ? "'$options->{VALUE}'" : 'undef' ;
my $history = "$action. value = $value_to_display, ${override}${force_lock}${lock}category = '$options->{CATEGORY}' at '$options->{FILE}:$options->{LINE}', status = $set_status" ;

my $history_data = {TIME => $self->{TIME_STAMP}, EVENT => $history} ;
$history_data->{HISTORY} = $options->{HISTORY} if exists $options->{HISTORY} ;
$history_data->{COMMENT} = $options->{COMMENT} if exists $options->{COMMENT} ;

push @{$config_variable->{HISTORY}}, $history_data ;

$self->{TIME_STAMP}++ ;

return(1) ;
}

#-------------------------------------------------------------------------------

sub SetAttribute
{

=head2 SetAttribute(NAME => $variable_name, ATTRIBUTE => $attribute, CATEGORY => $category)

This sub allows you to attach an attribute per variable (the attribute you set is per category) other than a value.
It will raise an exception if you try to set a variable that does not exists or if you try to set an attribute to a variable
in an aliased category.

	$config->SetAttribute(NAME => 'CC', ATTRIBUTE => 'attribute') ;
	
	# or directly in the 'Set' call
	
	$config->Set(NAME => 'CC', VALUE => 'CC', ATTRIBUTE => 'attribute') ;
	
	my ($attribute, $attribute_exists) = $config->GetAttribute(NAME => 'CC') ;

I<Arguments>

=over 2

=item * NAME => $variable_name - The variable name

=item * ATTRIBUTE => $attribute - A scalar attribute

=item * CATEGORY => $category - Category in which you want to set the attribute.

=back

I<Returns> - Nothing

=cut

my ($self, @options) = @_ ;

$self->CheckOptionNames($VALID_OPTIONS, @options) ;

my %options = @options ;

unless(defined $options{FILE})
	{
	my ($package, $file_name, $line) = caller() ;
	
	$options{FILE} = $file_name ;
	$options{LINE} = $line ;
	}

my $location = "$options{FILE}:$options{LINE}" ;

if(exists $options{CATEGORY})
	{
	if($self->{WARN_FOR_EXPLICIT_CATEGORY})
		{
		$self->{INTERACTION}{WARN}->("$self->{NAME}: Setting '$options{NAME}' using explicit category at '$location'!\n") ;
		}
	}
else
	{
	$options{CATEGORY} = $self->{DEFAULT_CATEGORY} ;
	}

#~ use Data::TreeDumper ;
#~ print DumpTree {Options => \%options, Self => $self} ;

$self->{INTERACTION}{DIE}->("$self->{NAME}: Invalid category '$options{CATEGORY}' at at '$location'!") unless exists $self->{VALID_CATEGORIES}{$options{CATEGORY}} ;
$self->{INTERACTION}{DIE}->("$self->{NAME}: Missing name at '$location'!") unless defined $options{NAME} ;
$self->{INTERACTION}{DIE}->("$self->{NAME}: Missing value at '$location'!") unless exists $options{VALUE} ;

my $value_to_display = defined $options{VALUE} ? "'$options{VALUE}'" : 'undef' ;

if(exists $self->{ALIASED_CATEGORIES}{$options{CATEGORY}})
	{
	$self->{INTERACTION}{DIE}->("$self->{NAME}: Can't set aliased category attribute (read only) at '$location'!")  ;
	}

# inform of action if option set
if($self->{VERBOSE})
	{
	$self->{INTERACTION}{INFO}->("$self->{NAME}: SetAttribute for '$options{CATEGORY}::$options{NAME}' to $value_to_display at '$location'.\n") ;
	}

if(exists $self->{CATEGORIES}{$options{CATEGORY}}{$options{NAME}})
	{
	my $config_variable = $self->{CATEGORIES}{$options{CATEGORY}}{$options{NAME}} ;
	$config_variable->{ATTRIBUTE} = $options{VALUE};	
	
	my $history = "SET_ATTRIBUTE. category = '$options{CATEGORY}', value = $value_to_display at '$location', status = OK." ;
	push @{$config_variable->{HISTORY}}, {TIME => $self->{TIME_STAMP}, EVENT => $history} ;

	$self->{TIME_STAMP}++ ;
	}
else
	{
	$self->{INTERACTION}{DIE}->("$self->{NAME}: Can't set attribute, variable '$options{NAME}' doesn't exist at '$location'!")  ;
	}
	
return(1) ;
}

#-------------------------------------------------------------------------------

sub GetAttribute
{

=head2 GetAttribute(NAME => $variable_name)

This sub returns the attribute as well as the existence of the attribute. If the attribute didn't exist, the value is
set to B<undef>. No warnings are  displayed if you query the attribute of a variable that does not have an attribute.

A warning message is displayed if you call this sub in void or scalar context.

	my ($attribute, $attribute_exists) = $config->GetAttribute(NAME => 'CC') ;

I<Arguments>

=over 2

=item * NAME => $variable_name - The name of the variable you want to get the attribute for

=back

I<Returns> - a list

=over 2

=item * The attribute

=item * A boolean. Set if the attribute existed

=back

I<Exceptions> - This sub will raise an exception if you query a variable that does not exists.

=cut

my ($self, @options) = @_ ;

$self->CheckOptionNames($VALID_OPTIONS, @options) ;

my %options = @options ;

unless(defined $options{FILE})
	{
	my ($package, $file_name, $line) = caller() ;
	
	$options{FILE} = $file_name ;
	$options{LINE} = $line ;
	}

my $location = "$options{FILE}:$options{LINE}" ;

if(defined wantarray)
	{
	unless(wantarray)
		{
		$self->{INTERACTION}{WARN}->("$self->{NAME}: GetAttribute: called in scalar context at '$location'!\n") ;
		}
	}
else
	{
	$self->{INTERACTION}{WARN}->("$self->{NAME}: 'GetAttribute' called in void context at '$location'!\n") ;
	}
	
if(exists $options{CATEGORY})
	{
	if($self->{WARN_FOR_EXPLICIT_CATEGORY})
		{
		$self->{INTERACTION}{WARN}->("$self->{NAME}: Setting '$options{NAME}' using explicit category at '$location'!\n") ;
		}
	}
else
	{
	$options{CATEGORY} = $self->{DEFAULT_CATEGORY} ;
	}

#~ use Data::TreeDumper ;
#~ print DumpTree {Options => \%options, Self => $self} ;

$self->{INTERACTION}{DIE}->("$self->{NAME}: Invalid category '$options{CATEGORY}' at at '$location'!") unless exists $self->{VALID_CATEGORIES}{$options{CATEGORY}} ;
$self->{INTERACTION}{DIE}->("$self->{NAME}: Missing name at '$location'!") unless defined $options{NAME} ;
$self->{INTERACTION}{DIE}->("$self->{NAME}: Unexpected field VALUE at '$location'!") if exists $options{VALUE} ;

# inform of action if option set
if($self->{VERBOSE})
	{
	$self->{INTERACTION}{INFO}->("$self->{NAME}: GetAttribute for '$options{CATEGORY}::$options{NAME}' at '$location'.\n") ;
	}

my @result ;

if(exists $self->{CATEGORIES}{$options{CATEGORY}}{$options{NAME}})
	{
	my $config_variable = $self->{CATEGORIES}{$options{CATEGORY}}{$options{NAME}} ;
	my $attribute_exist = exists $config_variable->{ATTRIBUTE};	
	
	if($attribute_exist)
		{
		@result = ($config_variable->{ATTRIBUTE}, $attribute_exist) ;
		}
	else
		{
		@result = (undef, $attribute_exist) ;
		}
	}
else
	{
	$self->{INTERACTION}{DIE}->("$self->{NAME}: Can't get attribute, variable '$options{NAME}' doesn't exist at '$location'!")  ;
	}

return(@result) ;
}

#-------------------------------------------------------------------------------

sub Validate
{

=head2 [p] Validate


=cut

my ($self,$options, $set_status, $location, $config_variable_exists)  = @_ ;

if($config_variable_exists)
	{
	my $config_variable = $self->{CATEGORIES}{$options->{CATEGORY}}{$options->{NAME}} ;

	# run variable validators
	for my $validator (keys %{$config_variable->{VALIDATORS}})
		{
		my$validator_origin = $config_variable->{VALIDATORS}{$validator}{ORIGIN} ;
		my $validator_sub = $config_variable->{VALIDATORS}{$validator}{SUB} ;
		
		if($self->{VERBOSE})
			{
			$self->{INTERACTION}{INFO}->("$self->{NAME}: running validator '$validator' defined at '$validator_origin' on '$options->{CATEGORY}::$options->{NAME}'.\n") ;
			}
			
		unless($validator_sub->($options->{VALUE}))
			{
			$self->{INTERACTION}{DIE}->
				("$self->{NAME}: Invalid value '$options->{VALUE}' for variable '$options->{NAME}'. Validator '$validator' defined at '$validator_origin'.\n") ;
			}
		}
	}
	
if(exists $options->{VALIDATORS})
	{
	# run local validator
	for my $validator (keys %{$options->{VALIDATORS}})
		{
		if($self->{VERBOSE})
			{
			$self->{INTERACTION}{INFO}->("$self->{NAME}: running local validator '$validator' defined at '$location'.\n") ;
			}
			
		unless($options->{VALIDATORS}{$validator}->($options->{VALUE}))
			{
			$self->{INTERACTION}{DIE}->
				("$self->{NAME}: Invalid value '$options->{VALUE}' for variable '$options->{NAME}'. Local validator '$validator' defined at '$location'.\n") ;
			}
		}
	}
	
return(1) ;
}

#-------------------------------------------------------------------------------

sub Get
{ ## no critic (ProhibitExcessComplexity)

=head2 Get(@named_arguments)

Returns the value associated with the variable passed as argument. If more than one category contains the variable,
the variable from the category with the highest priority, which is not overridden, will be used.

If the variable doesn't exist in the container, a warning is displayed and B<undef> is returned.

  my $config = new Config::Hierarchical(INITIAL_VALUES => [{NAME => 'CC', VALUE => 'gcc'}]) ;
  
  my $cc = $config->Get(NAME => 'CC') ;
  my $ld = $config->Get(NAME => 'LD', SILENT_NOT_EXISTS => 1) ;

I<Arguments>

=over 2

=item * SILENT_NOT_EXISTS

Setting this option will disable the warning generated when the variable doesn't exist in the container.

=item *  CATEGORIES_TO_EXTRACT_FROM

If set, B<Get> will only search in the specified categories. A warning is displayed if the categories are 
not in the same order as passed to the constructor.

=item *  GET_CATEGORY

If this option is set, B<Get> will return  the value _and_ the category it it comes from.

=back

I<Returns>

If B<GET_CATEGORY> is B<not> set:

=over 2

=item * The variable's value

=back

If B<GET_CATEGORY> B<is>  set:

=over 2

=item * The variable's value

=item * The category the value comes from

=back

I<Warnings>

This function verifies its calling context and will generate a warning if it is called in void context.

=cut

my ($self, @options) = @_ ;

$self->CheckOptionNames($VALID_OPTIONS, @options) ;

my %options = @options ;

unless(defined $options{FILE})
	{
	my ($package, $file_name, $line) = caller() ;
	
	$options{FILE} = $file_name ;
	$options{LINE} = $line ;
	}

my $location = "$options{FILE}:$options{LINE}" ;

if(exists $options{CATEGORIES_TO_EXTRACT_FROM})
	{
	if($self->{WARN_FOR_EXPLICIT_CATEGORY})
		{
		my $plural = 'y' ;
		$plural = 'ies' if (@{$options{CATEGORIES_TO_EXTRACT_FROM}} > 1) ;
		
		$self->{INTERACTION}{WARN}->("$self->{NAME}: Getting '$options{NAME}' using explicit categor$plural at '$location'!\n") ;
		}
	}

#~ use Data::TreeDumper ;
#~ print DumpTree {Options => \%options, Self => $self} ;

$self->{INTERACTION}{DIE}->("$self->{NAME}: Missing name at $location!") unless defined $options{NAME} ;

# inform of action if option set
if($self->{VERBOSE})
	{
	$self->{INTERACTION}{INFO}->("$self->{NAME}: Getting '$options{NAME}' at '$location'.\n") ;
	}

unless(defined wantarray)
	{
	$self->{INTERACTION}{WARN}->("$self->{NAME}: Getting '$options{NAME}' in void context at '$location'!\n") ;
	}

# run debug hook if any
if(defined $self->{INTERACTION}{DEBUG})
	{
	my $category = exists $options{CATEGORY} ? "$options{CATEGORY}::" : $EMPTY_STRING ;
	
	$self->{INTERACTION}{DEBUG}->
		(
		"Getting '$category$options{NAME}' at '$location'.",
		$self,
		\%options,
		) ;
	}
	
my @categories_to_extract_from ;
my %categories_to_extract_from ;
my $user_defined_categories_to_extract_from = 0 ;

if(exists $options{CATEGORIES_TO_EXTRACT_FROM})
	{
	$self->CheckCategoriesOrder(\%options, $location) ;
	
	@categories_to_extract_from = @{$options{CATEGORIES_TO_EXTRACT_FROM}} ;
	
	$user_defined_categories_to_extract_from++ ;
	%categories_to_extract_from = map {$_, 1} @categories_to_extract_from ;
	}
else
	{
	@categories_to_extract_from = @{$self->{CATEGORY_NAMES}} ;
	}


my ($value_found, $value, $found_in_category) = (0, undef, undef) ;

for my $category (@categories_to_extract_from)
	{
	my ($name_exists_in_category, $value_exists_in_category, $value_in_category, $name_in_category_is_overriden) 
		= $self->CheckVariableInCategory($category, $options{NAME}) ;
	
	next unless ($name_exists_in_category) ;
	
	# remember the value in case the overriding category is not in the list of categories to 
	# extract from
	$value_found++ ;
	
	$value             = $value_in_category ;
	$found_in_category = $category ;
	
	# check if lower priority category did an override
	if($name_in_category_is_overriden)
		{
		if(! $user_defined_categories_to_extract_from)
			{
			# get value from overriding category
			}
		else
			{
			# if this category was overridden by a category passed by the user
			# in CATEGORIES_TO_EXTRACT_FROM, use the overridden variable
			# otherwise, we are done
			
			my $current_categories_contain_overriding_category = 0 ;
			
			for my $override (@{ $name_in_category_is_overriden})
				{
				if(exists $categories_to_extract_from{$override->{CATEGORY}})
					{
					$current_categories_contain_overriding_category++ ;
					last ;
					}
				}
				
			if(! $current_categories_contain_overriding_category)
				{
				# we're done, return value from this category
				
				if($self->{VERBOSE})
					{
					$self->{INTERACTION}{INFO}->("\tfound in category '$found_in_category'.\n") ;
					}
				last ;
				}
			}
		}
	else
		{
		# we're done, return value from this category
		
		if($self->{VERBOSE})
			{
			$self->{INTERACTION}{INFO}->("\tfound in category '$found_in_category'.\n") ;
			}
		last ;
		}
	}


if($self->{LOG_ACCESS})	
	{
	push @{$self->{ACCESS_TO_VARIABLE}}, {%options} ;
	}

if(! $value_found)
	{
	#~ use Data::TreeDumper ;
	#~ warn DumpTree \%options ;
	#~ warn DumpTree $self ;
	
	if($self->{DIE_NOT_EXISTS} || $options{DIE_NOT_EXISTS})
		{
		$self->{INTERACTION}{DIE}->("$self->{NAME}: Variable '$options{NAME}' doesn't exist in categories [@categories_to_extract_from]at '$location'.\n") ;
		}
	else
		{
		if(! ($options{SILENT_NOT_EXISTS} ||  $self->{DISABLE_SILENT_OPTIONS}))
			{
			$self->{INTERACTION}{WARN}->("$self->{NAME}: Variable '$options{NAME}' doesn't exist in categories [@categories_to_extract_from]at '$location'. Returning undef!\n") ;
			}
		}
	}

if($options{GET_CATEGORY})
	{
	return($value, $found_in_category) ;
	}
else
	{
	return($value) ;
	}
}

#-------------------------------------------------------------------------------

sub CheckCategoriesOrder
{
	
=head2 [p] CheckCategoriesOrder


=cut

my ($self, $options, $location) = @_ ;

my @default_categories = @{ $self->{CATEGORY_NAMES} } ;

for my $category ( @{ $options->{CATEGORIES_TO_EXTRACT_FROM} })
	{
	$self->{INTERACTION}{DIE}->("$self->{NAME}: Invalid category '$category' at at '$location'!") unless exists $self->{VALID_CATEGORIES}{$category} ;

	shift @default_categories while(@default_categories && ($category ne $default_categories[0])) ;
	
	if(@default_categories)
		{
		shift @default_categories ;
		}
	else
		{
		$self->{INTERACTION}{WARN}->("$self->{NAME}: categories in 'CATEGORIES_TO_EXTRACT_FROM' in an unexpected order at '$location'.\n") ;
		last ;
		}
	}
	
return ;
}

#-------------------------------------------------------------------------------

sub SetMultiple
{
	
=head2 SetMultiple(\%options, \@variable_to_set, \@variable_to_set, ...)

Set multiple configuration in one call.

  $config->SetMultiple
	(
	{FORCE_LOCK => 1},
	
	[NAME => 'CC', VALUE => 'gcc', SILENT_OVERRIDE => 1],
	[NAME => 'LD', VALUE => 'ld'],
	) ;

I<Arguments>

=over 2

=item * \%options - An optional hash reference with options applied to each C<Set> call

=item * \@variable_to_set - An array reference containing the parameter for the C<Set> call

Multiple \@variable_to_set can be passed.

=back

I<Returns> - Nothing

see C<Set>.

=cut

my ($self, $options, @sets) = @_ ;

my ($package, $file_name, $line) = caller() ;

if('HASH' eq ref $options)
	{
	unless(defined $options->{FILE})
		{
		$options->{FILE} = $file_name ;
		$options->{LINE} = $line ;
		}
		
	}
else
	{
	unshift @sets, $options if defined $options ; 
	
	$options = {FILE => $file_name, LINE => $line} ;
	}
	
my $location = "$options->{FILE}:$options->{LINE}" ;

for my $set (@sets)
	{
	unless( 'ARRAY' eq ref $set)
		{
		$self->{INTERACTION}{DIE}->("$self->{NAME}: 'SetMultiple' must be passed array reference at '$location'!\n") ;
		}
	
	$self->Set(%{$options}, @{$set}) ;
	}

return(1) ;
}

#-------------------------------------------------------------------------------

sub GetMultiple
{

=head2 GetMultiple(\%options, @variables_to_get)

Get multiple configuration in one call.

  my $config = new Config::Hierarchical(INITIAL_VALUES => [{NAME => 'CC', VALUE => 'gcc'}]) ;
  
  my @values = $config->GetMultiple('CC') ;
  
  my @other_values = $config->GetMultiple
			(
			{SILENT_NOT_EXISTS => 1},
			'CC',
			'AR'
			) ;

I<Arguments>

=over 2

=item * \%options - An optional hash reference with options applied to each C<Get> call

=item * @variable_to_get - A list containing the names of the variables to get.

=back

Option B<GET_CATEGORY> will be ignored in this sub.

I<Returns> - Nothing

see C<Get>.

=cut

my ($self, $options, @names) = @_ ;

my ($package, $file_name, $line) = caller() ;

if('HASH' eq ref $options)
	{
	unless(defined $options->{FILE})
		{
		$options->{FILE} = $file_name ;
		$options->{LINE} = $line ;
		}
		
	}
else
	{
	unshift @names, $options if defined $options ; 
	
	$options = {FILE => $file_name, LINE => $line} ;
	}
	
my $location = "$options->{FILE}:$options->{LINE}" ;

if(defined wantarray)
	{
	unless(wantarray)
		{
		$self->{INTERACTION}{WARN}->("$self->{NAME}: 'GetMultiple' is not called in scalar context at '$location'!\n") ;
		}
	}
else
	{
	$self->{INTERACTION}{WARN}->("$self->{NAME}: 'GetMultiple' called in void context at '$location'!\n") ;
	}

my @values ;
for my $name (@names)
	{
	unless( $EMPTY_STRING eq ref $name)
		{
		$self->{INTERACTION}{DIE}->("$self->{NAME}: 'GetMultiple' must be passed scalars at '$location'!\n") ;
		}
	
	push @values, scalar($self->Get(%{$options}, NAME => $name, GET_CATEGORY => 0)) ;
	}
	
return(@values) ;
}

#-------------------------------------------------------------------------------

sub GetKeys
{
	
=head2 GetKeys()

  my @keys = $config->GetKeys() ;

Returns the names of the element in the config object.

I<Arguments>

=over 2

=item *  Optional, CATEGORIES_TO_EXTRACT_FROM

if set, B<GetKeys> will only search in the specified categories.

=back

I<Returns> 

The list of variables contained in the B<Config::Hierarchical> object.

I<Warnings>

A warning will be generated if I<GetKeys> is called in void context.

=cut

my ($self, @options) = @_ ;

my ($package, $file_name, $line) = caller() ;
my $location = "$file_name:$line" ;

$self->CheckOptionNames($VALID_OPTIONS, @options) ;

my %options = @options ;

if($self->{VERBOSE})
	{
	$self->{INTERACTION}{INFO}->("$self->{NAME}: 'GetKeys' at '$location'\n") ;
	}

unless(defined wantarray)
	{
	$self->{INTERACTION}{WARN}->("$self->{NAME}: 'GetKeys' called in void context at '$file_name:$line'!\n") ;
	}
	
my (%variables, @categories_to_extract_from) ;

if(exists $options{CATEGORIES_TO_EXTRACT_FROM})
	{
	@categories_to_extract_from = @{$options{CATEGORIES_TO_EXTRACT_FROM}} ;
	}
else
	{
	@categories_to_extract_from = @{$self->{CATEGORY_NAMES}} ;
	}
	
my %hash = map
			{
			$_ => 1
			} map
				{
				keys %{$self->{CATEGORIES}{$_}} ;
				}  @categories_to_extract_from ;

return(keys %hash) ;
}

#-------------------------------------------------------------------------------

sub GetKeyValueTuples
{

=head2 GetKeyValueTuples()

Returns a list of hash references containing the name and the value of each configuration variable
contained in the object. This can be useful when you you create config objects from data in other objects.

	my $config_1 = new Config::Hierarchical(.....) ;
	
	my $config_2 = new Config::Hierarchical
					(
					NAME => 'config 2',
					
					CATEGORY_NAMES         => ['PARENT', 'CURRENT'],
					DEFAULT_CATEGORY       => 'CURRENT',
					
					INITIAL_VALUES =>
						[
						# Initializing a category from another config
						map
							({
								{
								NAME     => $_->{NAME},
								VALUE    => $_->{VALUE}, 
								CATEGORY => 'PARENT',
								LOCK     => 1,
								HISTORY  => $config_1->GetHistory(NAME => $_->{NAME}),
								}
							} $config_1->GetKeyValueTuples()),
						
						{NAME => 'CC', VALUE => 1,},
						]
					) ;

I<Argument>

=over 2

=item *  Optional, CATEGORIES_TO_EXTRACT_FROM

If set, B<GetKeyValueTuples> will only search in the specified categories.

=back

I<Returns>

=over 2

=item *  A list of hash references. Each hash has a B<NAME> and B<VALUE> key.

=back

=cut

my ($self, @options) = @_ ;

my ($package, $file_name, $line) = caller() ;

if($self->{VERBOSE})
	{
	$self->{INTERACTION}{INFO}->("$self->{NAME}: 'GetKeyValueTuples' at '$file_name:$line'\n") ;
	}

unless(defined wantarray)
	{
	$self->{INTERACTION}{WARN}->("$self->{NAME}: 'GetKeyValueTuples' in void context at '$file_name:$line'!\n") ;
	}

# run debug hook if any
if(defined $self->{INTERACTION}{DEBUG})
	{
	$self->{INTERACTION}{DEBUG}->("'GetKeyValueTuples' at '$file_name:$line'.", $self, \@options,) ;
	}

my @list ;
my %hash = %{$self->GetHashRef(@options)} ;
 
while(my($n, $v) = each %hash)
	{
	push @list, {NAME => $n, VALUE => $v} ;
	}
	
return(@list) ;
}

#-------------------------------------------------------------------------------

sub GetHashRef
{

=head2 GetHashRef()

  my $hash_ref = $config->GetHashRef() ;

I<Arguments> - None

This function will generate an error if any argument is passed to it.

I<Returns> - A hash reference containing a copy of all the elements in the container.

I<Warnings>

C<GetHashRef> will generate a warning if:

=over 2

=item * it is called in void context

=item * it is called in array context

=back

=cut

my ($self, @options) = @_ ;

my ($package, $file_name, $line) = caller() ;
my $location = "$file_name:$line" ;

$self->CheckOptionNames($VALID_OPTIONS, @options) ;

my %options = @options ;

if($self->{VERBOSE})
	{
	$self->{INTERACTION}{INFO}->("$self->{NAME}: 'GetHashRef' at '$location'\n") ;
	}

if(defined wantarray)
	{
	if(wantarray)
		{
		$self->{INTERACTION}{WARN}->("$self->{NAME}: 'GetHashRef' is called in array context at '$file_name:$line'!\n") ;
		}
	}
else
	{
	$self->{INTERACTION}{WARN}->("$self->{NAME}: 'GetHashRef' called in void context at '$file_name:$line'!\n") ;
	}
	
my (%variables, @categories_to_extract_from) ;

if(exists $options{CATEGORIES_TO_EXTRACT_FROM})
	{
	@categories_to_extract_from = @{$options{CATEGORIES_TO_EXTRACT_FROM}} ;
	}
else
	{
	@categories_to_extract_from = @{$self->{CATEGORY_NAMES}} ;
	}
	
return 
	{
	map
		{
		$_ => scalar($self->Get(NAME => $_, CATEGORIES_TO_EXTRACT_FROM => [@categories_to_extract_from], FILE => $file_name, LINE => $line))
		} map
			{
			keys %{$self->{CATEGORIES}{$_}} ;
			}  @categories_to_extract_from
	} ;
}


#-------------------------------------------------------------------------------

sub SetDisplayExplicitCategoryWarningOption
{

=head2 SetDisplayExplicitCategoryWarningOption($boolean)

  $config->SetDisplayExplicitCategoryWarningOption(1) ;
  $config->SetDisplayExplicitCategoryWarningOption(0) ;

I<Arguments>

=over 2

=item * $boolean - controls if messages are displayed if an explicit category is used in C<Get> or C<Set>. 

=back

I<Return> - Nothing

=cut

my ($self, $value) = @_ ;

$self->{WARN_FOR_EXPLICIT_CATEGORY} = $value ;

if($self->{VERBOSE})
	{
	my ($package, $file_name, $line) = caller() ;
	$self->{INTERACTION}{INFO}->("$self->{NAME}: Setting 'WARN_FOR_EXPLICIT_CATEGORY' to '$value' at '$file_name:$line'.\n") ;
	}
	
return(1) ;
}

#-------------------------------------------------------------------------------

sub SetDisableSilentOptions
{

=head2 SetDisableSilentOptions($boolean)

  $config->SetDisableSilentOptions(1) ;
  $config->SetDisableSilentOptions(0) ;

I<Arguments>

=over 2

=item * $boolean - controls if messages are displayed regardless of local warning disabling options

This is useful when debugging your configuration as it forces all the warning to be displayed.

=back

I<Return> - Nothing


=cut

my ($self, $silent) = @_ ;

$self->{DISABLE_SILENT_OPTIONS} = $silent ;

if($self->{VERBOSE})
	{
	my ($package, $file_name, $line) = caller() ;
	$self->{INTERACTION}{INFO}->("$self->{NAME}: Setting 'DISABLE_SILENT_OPTIONS' to '$silent' at '$file_name:$line'.\n") ;
	}
	
return(1) ;
}

#-------------------------------------------------------------------------------
	
sub LockCategories
{

=head2 LockCategories(@categories)

Locks the categories passed as argument. A variable in a locked category can not be set.
An attempt to set a locked variable will generate an error. B<FORCE_LOCK> has no effect on locked categories.

	$config->LockCategories('PARENT', 'OTHER') ;

I<Arguments>

=over 2 

=item * @categories - a list of categories to lock

=back

I<Returns> - Nothing

I<Exceptions> - An exception is generated if you try to lock a category that doesn't exist.

See C<UnlockCategories>.

=cut

my ($self, @categories) = @_ ;

my ($package, $file_name, $line) = caller() ;
my $location = "$file_name:$line" ;

for my $category (@categories)
	{
	$self->{INTERACTION}{DIE}->("$self->{NAME}: Invalid category '$category' at '$location'!") unless exists $self->{VALID_CATEGORIES}{$category} ;
	$self->{LOCKED_CATEGORIES}{$category} = 1 ;
	}
	
return(1) ;
}

#-------------------------------------------------------------------------------
	
sub Lock
{

=head2 Lock(NAME => $variable_name, CATEGORY => $category)

Locks a variable in the default category or an explicit category. A locked variable can not be set.

To set a locked variable, B<FORCE_LOCK> can be used. B<FORCE_LOCK> usually pinpoints a problem
in your configuration.

  $config->Lock(NAME => 'CC') ;
  $config->Lock(NAME => 'CC', CATEGORY => 'PARENT') ;

I<Arguments>

=over 2 

=item * NAME => $variable_name - Name of the variable to lock

=item * CATEGORY =>  $category - Name of the category containing the variable

=back

I<Returns> - Nothing

I<Exceptions> - An exception is generated if you try to lock a variable that doesn't exist.

See C<Set>.

=cut

my ($self, @options) = @_ ;

if (@options % 2)
	{
	$self->{INTERACTION}{DIE}->('Invalid number of argument!') ;
	}

my %options = @options ;

unless(defined $options{FILE})
	{
	my ($package, $file_name, $line) = caller() ;
	
	$options{FILE} = $file_name ;
	$options{LINE} = $line ;
	}

my $location = "$options{FILE}:$options{LINE}" ;

$options{CATEGORY} = $self->{DEFAULT_CATEGORY} unless exists $options{CATEGORY} ;

$self->CheckOptionNames($VALID_OPTIONS, %options) ;

$self->{INTERACTION}{DIE}->("$self->{NAME}: Invalid category at '$location'!") unless exists $self->{VALID_CATEGORIES}{$options{CATEGORY}} ;
$self->{INTERACTION}{DIE}->("$self->{NAME}: Missing name at '$location'!") unless defined $options{NAME} ;

if($self->{VERBOSE})
	{
	$self->{INTERACTION}{INFO}->("$self->{NAME}: Locking '$options{CATEGORY}::$options{NAME}' at '$location'.\n") ;
	}

if(exists $self->{CATEGORIES}{$options{CATEGORY}}{$options{NAME}})
	{
	my $config_variable = $self->{CATEGORIES}{$options{CATEGORY}}{$options{NAME}} ;
	
	$config_variable->{LOCKED} = $location ;
	
	my $history = "LOCK. category = '$options{CATEGORY}' at '$options{FILE}:$options{LINE}', status = Lock: OK." ;
	push @{$config_variable->{HISTORY}}, {TIME => $self->{TIME_STAMP}, EVENT => $history} ;

	$self->{TIME_STAMP}++ ;
	}
else
	{
	$self->{INTERACTION}{DIE}->("$self->{NAME}: Locking unexisting '$options{CATEGORY}::$options{NAME}' at '$location'.\n") ;
	}

return(1) ;
}

#-------------------------------------------------------------------------------
	
sub UnlockCategories
{

=head2 UnlockCategories(@categories)

Unlocks the categories passed as argument. 

	$config->UnlockCategories('PARENT', 'OTHER') ;

I<Arguments>

=over 2 

=item * @categories - a list of categories to unlock

=back

I<Returns> - Nothing

See C<LockCategories>.

=cut


my ($self, @categories) = @_ ;

for my $category (@categories)
	{
	delete $self->{LOCKED_CATEGORIES}{$category} ;
	}
	
return(1) ;
}

#-------------------------------------------------------------------------------

sub Unlock
{

=head2 Unlock(NAME => $variable_name, CATEGORY => $category)

Unlocks a variable in the default category or an explicit category.

  $config->Unlock(NAME => 'CC') ;
  $config->Unlock(NAME => 'CC', CATEGORY => 'PARENT') ;

I<Arguments>

=over 2 

=item * NAME => $variable_name - Name of the variable to unlock

=item * CATEGORY =>  $category - Name of the category containing the variable

=back

I<Returns> - Nothing

I<Exceptions> - An exception is generated if you pass a category that doesn't exist.

See C<Lock>.

=cut

my ($self, @options) = @_ ;

if (@options % 2)
	{
	$self->{INTERACTION}{DIE}->('Invalid number of argument!') ;
	}

my %options = @options ;

unless(defined $options{FILE})
	{
	my ($package, $file_name, $line) = caller() ;
	
	$options{FILE} = $file_name ;
	$options{LINE} = $line ;
	}

my $location = "$options{FILE}:$options{LINE}" ;

$options{CATEGORY} = $self->{DEFAULT_CATEGORY} unless exists $options{CATEGORY} ;

$self->CheckOptionNames($VALID_OPTIONS, %options) ;

$self->{INTERACTION}{DIE}->("$self->{NAME}: Invalid category at '$location'!") unless exists $self->{VALID_CATEGORIES}{$options{CATEGORY}} ;
$self->{INTERACTION}{DIE}->("$self->{NAME}: Missing name at '$location'!") unless defined $options{NAME} ;

if($self->{VERBOSE})
	{
	$self->{INTERACTION}{INFO}->("$self->{NAME}: Unlocking '$options{CATEGORY}::$options{NAME}' at '$location'.\n") ;
	}
	
if(exists $self->{CATEGORIES}{$options{CATEGORY}}{$options{NAME}})
	{
	my $config_variable = $self->{CATEGORIES}{$options{CATEGORY}}{$options{NAME}} ;
	
	delete $config_variable->{LOCKED} ;
	
	my $history = "UNLOCK. category = '$options{CATEGORY}' at '$options{FILE}:$options{LINE}', status = Unlock: OK." ;
	push @{$config_variable->{HISTORY}}, {TIME => $self->{TIME_STAMP}, EVENT => $history} ;
	
	$self->{TIME_STAMP}++ ;
	}

return(1) ;
}
  
#-------------------------------------------------------------------------------

sub IsCategoryLocked
{

=head2 IsCategoryLocked($category)

Query the lock state of a category. 

	$config->IsCategoryLocked('PARENT') ;

I<Arguments>

=over 2 

=item * $category - Name of the category containing to query

=back

I<Returns> - A boolean

I<Exceptions> - Querying the lock state of a category that doesn't exist generates an exception.

=cut

my ($self, $category) = @_ ;

my ($package, $file_name, $line) = caller() ;
my $location = "$file_name:$line" ;

$self->{INTERACTION}{DIE}->("$self->{NAME}: No category at '$location'!") unless defined $category ;
$self->{INTERACTION}{DIE}->("$self->{NAME}: Invalid category '$category' at '$location'!") unless exists $self->{VALID_CATEGORIES}{$category} ;

if(exists $self->{LOCKED_CATEGORIES}{$category})
	{
	return(1) ;
	}
else
	{
	return(0) ;
	}

}

#-------------------------------------------------------------------------------

sub IsLocked
{

=head2 IsLocked(NAME => $variable_name, CATEGORY => $category)

Query the lock state of a variable.

  $config->IsLocked(NAME => 'CC') ;
  $config->IsLocked(NAME => 'CC', CATEGORY => 'PARENT') ;

I<Arguments>

=over 2 

=item * NAME => $variable_name - Name of the variable to query

=item * Optional, CATEGORY =>  $category - Name of the category containing the variable

=back

I<Returns> - A boolean

I<Exceptions> - Querying the lock state of a variable that doesn't exist does not generate an exception.

=cut

my ($self, @options) = @_ ;

if (@options % 2)
	{
	$self->{INTERACTION}{DIE}->('Invalid number of argument!') ;
	}

my %options = @options ;

unless(defined $options{FILE})
	{
	my ($package, $file_name, $line) = caller() ;
	
	$options{FILE} = $file_name ;
	$options{LINE} = $line ;
	}

my $location = "$options{FILE}:$options{LINE}" ;

$options{CATEGORY} = $self->{DEFAULT_CATEGORY} unless exists $options{CATEGORY} ;

$self->CheckOptionNames($VALID_OPTIONS, %options) ;

$self->{INTERACTION}{DIE}->("$self->{NAME}: Invalid category '$options{CATEGORY}' at '$location'!") unless exists $self->{VALID_CATEGORIES}{$options{CATEGORY}} ;
$self->{INTERACTION}{DIE}->("$self->{NAME}: Missing name at '$location'!") unless defined $options{NAME} ;

if($self->{VERBOSE})
	{
	$self->{INTERACTION}{INFO}->("$self->{NAME}: Checking Lock of '$options{CATEGORY}::$options{NAME}' at '$location'.\n") ;
	}
	
my $locked = undef ;

if(exists $self->{CATEGORIES}{$options{CATEGORY}}{$options{NAME}})
	{
	if(exists $self->{CATEGORIES}{$options{CATEGORY}}{$options{NAME}}{LOCKED})
		{
		$locked = 1 ;
		}
	else
		{
		$locked = 0 ;
		}
	}

return($locked) ;
}
  
#-------------------------------------------------------------------------------

sub Exists
{

=head2 Exists(NAME => $variable_name, CATEGORIES_TO_EXTRACT_FROM =>  \@categories)

  $config->Exists(NAME => 'CC') ;

Returns B<true> if the variable exist, B<false> otherwise. All the categories are checked.

I<Arguments>

=over 2 

=item * NAME => $variable_name - Name of the variable to check

=item * CATEGORIES_TO_EXTRACT_FROM =>  \@categories - list of category names

=back

I<Returns> - A boolean

I<Exceptions> - An exception is generated if you pass a category that doesn't exist.

=cut

my ($self, @options) = @_ ;

if (@options % 2)
	{
	$self->{INTERACTION}{DIE}->('Invalid number of argument!') ;
	}

my %options = @options ;

unless(defined $options{FILE})
	{
	my ($package, $file_name, $line) = caller() ;
	
	$options{FILE} = $file_name ;
	$options{LINE} = $line ;
	}

my $location = "$options{FILE}:$options{LINE}" ;

$self->CheckOptionNames($VALID_OPTIONS, %options) ;

$self->{INTERACTION}{DIE}->("$self->{NAME}: Missing name at '$location'!") unless defined $options{NAME} ;
$self->{INTERACTION}{DIE}->("$self->{NAME}: 'CATEGORY' not used at '$location'!") if exists $options{CATEGORY} ;

if($self->{VERBOSE})
	{
	$self->{INTERACTION}{INFO}->("$self->{NAME}: Checking Existance of '$options{NAME}' at '$location'.\n") ;
	}
	
my @categories_to_extract_from ;

if(exists $options{CATEGORIES_TO_EXTRACT_FROM})
	{
	if(defined $options{CATEGORIES_TO_EXTRACT_FROM})
		{
		@categories_to_extract_from = @{$options{CATEGORIES_TO_EXTRACT_FROM}} ;
		}
	else
		{
		$self->{INTERACTION}{DIE}->("$self->{NAME}: undefined category 'CATEGORIES_TO_EXTRACT_FROM' at '$location'!") ;
		}
	}
else
	{
	@categories_to_extract_from = @{$self->{CATEGORY_NAMES}} ;
	}
	
my ($exists) = (0) ;

for my $category (@categories_to_extract_from)
	{
	$self->{INTERACTION}{DIE}->("$self->{NAME}: Invalid category '$category' at '$location'!") unless exists $self->{VALID_CATEGORIES}{$category} ;
		
	if(exists $self->{CATEGORIES}{$category}{$options{NAME}})
		{
		$exists++ ;
		}
	}

return($exists) ;
}
  
#-------------------------------------------------------------------------------
  
sub GetHistory
{

=head2 GetHistory(NAME => $variable_name, CATEGORIES_TO_EXTRACT_FROM => \@categories)

Returns a variable history.

  $history = $config->GetHistory(NAME => 'CC') ;
  $history = $config->GetHistory(NAME => 'CC', CATEGORIES_TO_EXTRACT_FROM => ['PARENT']) ;

I<Arguments>

=over 2 

=item * NAME => $variable_name - Name of the variable to check

=item * CATEGORIES_TO_EXTRACT_FROM =>  \@categories - list of category names

=back

I<Returns> - Returns a reference to the variable's history or an empty list  if the variable doesn't exist.

	my $config = new Config::Hierarchical
					(
					NAME => 'Test config',
					
					CATEGORY_NAMES         => ['PARENT', 'CURRENT'],
					DEFAULT_CATEGORY       => 'CURRENT',
							
					INITIAL_VALUES  =>
						[
						{NAME => 'CC', CATEGORY => 'PARENT', VALUE => 'parent'},
						] ,
					) ;
					
	$config->Set(NAME => 'CC', OVERRIDE => 1, VALUE => 'override value') ;
	
	my($value, $category) = $config->Get(NAME => 'CC',  GET_CATEGORY => 1) ;
	
	my $title = "'CC' = '$value' from category '$category':" ;
	print DumpTree($config->GetHistory(NAME=> 'CC'), $title, DISPLAY_ADDRESS => 0) ;

Would print as:

	'CC' = 'override value' from category 'CURRENT':
	|- 0 
	|  |- EVENT = . CREATE AND SET. value = 'parent', category = 'PARENT' at 'nadim2.pl:21', status = OK. 
	|  `- TIME = 0 
	`- 1 
	   |- EVENT = value = CREATE AND SET, OVERRIDE. 'override value', category = 'CURRENT' at 'nadim2.pl:34', status =
	   |  Overriding 'PARENT::CC' (existed, value was different).OK. 
	   `- TIME = 1 

while

	my($value, $category) = $config->Get(NAME => 'CC', GET_CATEGORY => 1, CATEGORIES_TO_EXTRACT_FROM => ['PARENT']) ;
	
	my $title = "'CC' = '$value' from category '$category':" ;
	print DumpTree($config->GetHistory(NAME=> 'CC', CATEGORIES_TO_EXTRACT_FROM => ['PARENT']), $title, DISPLAY_ADDRESS => 0) ;

Would print as:

	'CC' = 'parent' from category 'PARENT':
	`- 0 
	   |- EVENT = value = CREATE AND SET. 'parent', category = 'PARENT' at 'nadim2.pl:21', status = OK. 
	   `- TIME = 0 

=head3 Explicit history and comments

If you passed a B<HISTORY> or a B<COMMENT> when you created or modified a variable, that information
will be included in the history structure returned by B<GetHistory>.

	my $config3 = new Config::Hierarchical
					(
					NAME => 'config3',
					...
					INITIAL_VALUES  =>
						[
						{
						COMMENT => "history and value from category 2",	
						NAME => 'CC', CATEGORY => 'PARENT', VALUE => $value2,
						HISTORY => $history2,
						},
						] ,
					...
					) ;
					
	my($value3, $category3) = $config3->Get(NAME => 'CC',  GET_CATEGORY => 1) ;
	my $title3 = "'CC' = '$value3' from category '$category3':" ;
	my $history3 = $config3->GetHistory(NAME=> 'CC') ;
	print DumpTree($history3, $title3, DISPLAY_ADDRESS => 0) ;

Would print as:

	'CC' = '3' from category 'PARENT':
	|- 0
	|  |- COMMENT = history and value from config 2
	|  |- EVENT = CREATE, SET HISTORY AND SET. value = '3', category = 'PARENT' at 'history.pl:56', status = OK.
	|  |- HISTORY
	|  |  |- 0
	...

=head3 Aliased category history

if you used an aliased category, The history structure returned by B<GetHistory> will automatically include the 
history of the aliased config.

	my $config0 = (...) ;
	my $config1 = (...) ;
	my $config2 = new Config::Hierarchical
					(
					...
					INITIAL_VALUES =>
						[
						{
						CATEGORY       => 'PBS',
						ALIAS_CATEGORY => $config1,
						HISTORY        => ....,
						COMMENT        => ....,
						},
					...
					) ;
					
	...
	print DumpTree $config_3->GetHistory( NAME => 'CC1'), 'CC1', DISPLAY_ADDRESS => 0;

Would print as:

	CC1
	|- 0
	|  |- HISTORY FROM ALIASED CATEGORY 'config 1'
	|  |  |- 0
	|  |  |  |- HISTORY FROM ALIASED CATEGORY 'config 0'
	|  |  |  |  `- 0
	|  |  |  |     |- EVENT = CREATE AND SET. value = '1', category = 'CURRENT' at 'nadim.pl:21', status = OK.
	|  |  |  |     `- TIME = 0
	|  |  |  `- TIME = 2
	|  |  |- 1
	|  |  |  |- EVENT = CREATE AND SET. value = '1', category = 'A' at 'nadim.pl:33', status = OK.
	|  |  |  `- TIME = 3
	|  |  `- 2
	|  |     |- EVENT = Set. value = '1.1', category = 'A' at 'nadim.pl:50', status = OK.
	|  |     `- TIME = 6
	|  `- TIME = 3
	|- 1
	|  |- EVENT = CREATE AND SET, OVERRIDE. value = 'A', category = 'A' at 'nadim.pl:64', status = OK.
	|  `- TIME = 4
	`- 2
	   |- EVENT = SET, OVERRIDE. value = 'A2', category = 'A' at 'nadim.pl:65', status = OK.
	   `- TIME = 5

=head4 Compact display

Given the following Data::TreeDumper filter

	sub Compact
	{
	my ($s, $level, $path, $keys, $setup, $arg) = @_ ;
	
	if('ARRAY' eq ref $s)
		{
		my ($index, @replacement, @keys) = (0) ;
		
		for my $entry( @$s)
			{
			if(exists $entry->{EVENT})
				{
				push @replacement, $entry->{EVENT} ; #. 'time: ' . $entry->{TIME};
				push@keys, $index++ ;
				}
			else
				{
				my ($aliased_history_name) = grep {$_ ne 'TIME'} keys %$entry ;
				
				push @replacement, $entry->{$aliased_history_name} ;
				push@keys, [$index, "$index = $aliased_history_name"] ;
				$index++ ;
				}
			}
		
		return('ARRAY', \@replacement, @keys) ;
		}
	}
	
	print DumpTree $config_2->GetHistory( NAME => 'CC1'), 'CC1', DISPLAY_ADDRESS => 0, FILTER => \&Compact ;

the above output  becomes:

	CC1
	|- 0 = HISTORY FROM ALIASED CATEGORY 'config 1'
	|  |- 0 = HISTORY FROM ALIASED CATEGORY 'config 0'
	|  |  `- 0 = CREATE AND SET. value = '1', category = 'CURRENT' at 'nadim.pl:21', status = OK.
	|  |- 1 = CREATE AND SET. value =  '1', category = 'A' at 'nadim.pl:33', status = OK.
	|  `- 2 = SET. value = '1.1', category = 'A' at 'nadim.pl:50', status = OK.
	|- 1 = CREATE AND SET, OVERRIDE. value = 'A', category = 'A' at 'nadim.pl:64', status = OK.
	`- 2 = SET, OVERRIDE. value = 'A2', category = 'A' at 'nadim.pl:65', status = OK.

Note that comments are also removed.

=cut

my ($self, @options) = @_ ;

if (@options % 2)
	{
	$self->{INTERACTION}{DIE}->('Invalid number of argument!') ;
	}

my %options = @options ;

unless(defined $options{FILE})
	{
	my ($package, $file_name, $line) = caller() ;
	
	$options{FILE} = $file_name ;
	$options{LINE} = $line ;
	}

my $location = "$options{FILE}:$options{LINE}" ;

$self->CheckOptionNames($VALID_OPTIONS, %options) ;

$self->{INTERACTION}{DIE}->("$self->{NAME}: Missing name at '$location'!") unless defined $options{NAME} ;
$self->{INTERACTION}{DIE}->("$self->{NAME}: bad argument 'CATEGORY' did you mean 'CATEGORIES_TO_EXTRACT_FROM'? at '$location'!") if exists $options{CATEGORY} ;

my @history ;
my @categories_to_extract_from ;

if(exists $options{CATEGORIES_TO_EXTRACT_FROM})
	{
	if(defined $options{CATEGORIES_TO_EXTRACT_FROM})
		{
		@categories_to_extract_from = @{$options{CATEGORIES_TO_EXTRACT_FROM}} ;
		}
	else
		{
		$self->{INTERACTION}{DIE}->("$self->{NAME}: undefined category 'CATEGORIES_TO_EXTRACT_FROM' at '$location'!") ;
		}
	}
else
	{
	@categories_to_extract_from = @{$self->{CATEGORY_NAMES}} ;
	}
	
for my $category (@categories_to_extract_from)
	{
	$self->{INTERACTION}{DIE}->("$self->{NAME}: Invalid category '$category' at '$location'!") unless exists $self->{VALID_CATEGORIES}{$category} ;
		
	push @history, $self->GetVariableHistory($category, $options{NAME})  ;
	}
	
@history = sort {$a->{TIME} <=> $b->{TIME}} @history ;

return(\@history) ;
}

#-------------------------------------------------------------------------------

sub GetVariableHistory
{
	
=head2 [p] GetVariableHistory

This shall not be used directly. Use C<GetHistory>.

=cut

my ($self, $category, $name) = @_ ;

if(exists $self->{ALIASED_CATEGORIES}{$category})
	{
	my $aliased = tied(%{ $self->{CATEGORIES}{$category} }) ;
	my $aliased_history = $aliased->{CONFIG}->GetHistory(NAME => $name) ;
	
	if(@{$aliased_history})
		{
		return 
			{
			"HISTORY FROM '$category' ALIASED TO '$aliased->{CONFIG}{NAME}'" => $aliased_history,
			TIME => $self->{ALIASED_CATEGORIES}{$category}{TIME_STAMP},
			} ;
		}
	else
		{
		return ;
		}
	}
else
	{
	if(exists $self->{CATEGORIES}{$category}{$name})
		{
		return(@{$self->{CATEGORIES}{$category}{$name}{HISTORY}}) ;
		}
	else
		{
		return  ;
		}
	}
}

#-------------------------------------------------------------------------------

sub GetHistoryDump
{

=head2 GetHistoryDump(@named_arguments)

Returns a dump, of the variable history, generated by B<Data::TreeDumper::DumpTree>. 

  $dump = $config->GetHistoryDump(NAME => 'CC') ;
  
  $dump = $config->GetHistoryDump(CATEGORIES_TO_EXTRACT_FROM => ['A', 'B'], NAME => 'CC', DATA_TREEDUMPER_OPTIONS => []) ;

I<Arguments>

=over 2 

=item * NAME => $variable_name - Name of the variable to check

=item * Optional, CATEGORIES_TO_EXTRACT_FROM =>  \@categories - list of category names

=back

I<Returns> - Returns a reference to the variable's history or an empty list  if the variable doesn't exist.


See L<Data::TreeDumper>.

=cut

my ($self, @options) = @_ ;

if (@options % 2)
	{
	$self->{INTERACTION}{DIE}->('Invalid number of argument!') ;
	}

my %options = @options ;

$self->CheckOptionNames($VALID_OPTIONS, %options) ;

unless(defined $options{FILE})
	{
	my ($package, $file_name, $line) = caller() ;
	
	$options{FILE} = $file_name ;
	$options{LINE} = $line ;
	}

my $location = "$options{FILE}:$options{LINE}" ;

$self->{INTERACTION}{DIE}->("$self->{NAME}: Missing name at '$location'!") unless defined $options{NAME} ;

my ($config_name, $config_location) = $self->GetInformation() ;
my $config_information = "from config '$config_name' created at '$config_location'" ;

my @categories_to_extract_from ;
if(exists $options{CATEGORIES_TO_EXTRACT_FROM})
	{
	@categories_to_extract_from = (CATEGORIES_TO_EXTRACT_FROM => $options{CATEGORIES_TO_EXTRACT_FROM}) ;
	}
	
my @data_treedumper_options ;
if(exists $options{DATA_TREEDUMPER_OPTIONS})
	{
	@data_treedumper_options = @{ $options{DATA_TREEDUMPER_OPTIONS} } ;
	}

return
	(
	DumpTree
		(
		$self->GetHistory(NAME => $options{NAME}, @categories_to_extract_from),
		"History for variable '$options{NAME}' $config_information:",
		DISPLAY_ADDRESS => 0,
		@data_treedumper_options
		) 
	) ;
}

#-------------------------------------------------------------------------------

sub GetAccessLog
{

=head2 GetAccessLog()

Returns a list of all the B<Config::Hierarchical> accesses.

	my $config = new Config::Hierarchical( LOG_ACCESS => 1, ...) ;
	
	my $value = $config->Get(NAME => 'A') ;
	$value    = $config->Get(NAME => 'B') ;
	$value    = $config->Get(NAME => 'A', CATEGORIES_TO_EXTRACT_FROM => ['PARENT']) ;
	
	my $access_log = $config->GetAccessLog() ;

would return the following structure :

	access log:
	|- 0 
	|  |- FILE = test.pl 
	|  |- LINE = 28 
	|  `- NAME = A 
	|- 1 
	|  |- FILE = test.pl 
	|  |- LINE = 29 
	|  `- NAME = B 
	`- 2 
	   |- CATEGORIES_TO_EXTRACT_FROM 
	   |  `- 0 = PARENT 
	   |- FILE = test.pl 
	   |- LINE = 30 
	   `- NAME = A 

I<Arguments> - None

I<Returns> - An array reference containing all the read accesses.

If B<LOG_ACCESS> was not set, an empty array reference is returned.

=cut

my ($self) = @_ ;

if(exists $self->{ACCESS_TO_VARIABLE})	
	{
	return($self->{ACCESS_TO_VARIABLE}) ;
	}
else
	{
	return [] ;
	}
}

#-------------------------------------------------------------------------------

sub GetDump
{

=head2 GetDump()

  $dump = $config->GetDump(@data_treedumper_options) ;
  $dump = $config->GetDump(@data_treedumper_options) ;

I<Arguments>

=over 2

=item * @data_treedumper_options - A list of options forwarded to L<Data::TreeDumper::DumpTree>.

=back

I<Returns>

A dump, of the Config::Hierarchical object, generated by L<Data::TreeDumper::DumpTree>. 

See L<Data::TreeDumper>.

=cut

my ($self, @data_treedumper_options) = @_ ;

my ($package, $file_name, $line) = caller() ;

use Data::TreeDumper ;

my $sort_categories =
	sub
		{
		# DTD dumps hash with sorted keys
		# we display the categories in hierarchical order
		
	        my ($s, $level, $path, $keys) = @_ ;
		
		if($level == 1 && $path eq q<{'CATEGORIES'}>)
			{
			return('HASH', undef, @{$self->{CATEGORY_NAMES}}) ;
			}
		else
			{
			return(Data::TreeDumper::DefaultNodesToDisplay($s)) ;
			}
		} ;
		
return(DumpTree($self, $self->{NAME}, FILTER => $sort_categories, @data_treedumper_options)) ;
}
  
#-------------------------------------------------------------------------------

1 ;

=head1 BUGS AND LIMITATIONS

None so far.

=head1 AUTHOR

	Khemir Nadim ibn Hamouda
	CPAN ID: NKH
	mailto:nadim@khemir.net

=head1 LICENSE AND COPYRIGHT

Copyright 2006-2007 Khemir Nadim. All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Config::Hierarchical

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Config-Hierarchical>

=item * RT: CPAN's request tracker

Please report any bugs or feature requests to  L <bug-config-hierarchical@rt.cpan.org>.

We will be notified, and then you'll automatically be notified of progress on
your bug as we make changes.

=item * Search CPAN

L<http://search.cpan.org/dist/Config-Hierarchical>

=back

=head1 SEE ALSO

L<Config::Hierarchical::Tie::ReadOnly>

L<Config::Hierarchical::Delta>

=cut
