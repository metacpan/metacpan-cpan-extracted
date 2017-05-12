
package App::Chained ;

use strict;
use warnings ;
use Carp ;

BEGIN 
{
use Sub::Exporter -setup => 
	{
	exports => [ qw() ],
	groups  => 
		{
		all  => [ qw() ],
		}
	};
	
use vars qw ($VERSION);
$VERSION     = '0.02';
}

#-------------------------------------------------------------------------------

use English qw( -no_match_vars ) ;

use Readonly ;
Readonly my $EMPTY_STRING => q{} ;
Readonly my $SCALAR => q{} ;

use Carp qw(carp croak confess) ;
use List::MoreUtils qw(any none first_index) ;
use Getopt::Long ;
	

#-------------------------------------------------------------------------------

=head1 NAME

App::Chained - Wrapper to sub applications in the Git fashion - No modification to your scripts, modules.

=head1 SYNOPSIS

A complete example can be found in I< test_wrapper.p test_application test_module.pm test_templatel> in the distribution.

 package App::Chained::Test ;
 use parent 'App::Chained' ;
 our $VERSION = '0.03' ;
 
 =head1 THIS WRAPPER DOCUMENTATION
 
 This will be automatically extracted as we set the B<help> fields to B<\&App::Chained::get_help_from_pod> 
 
 =cut

 sub run
 {
 my ($invocant, @setup_data) = @_ ;
 
 my $chained_app = 
	App::Chained->new
		(
		help => \&App::Chained::get_help_from_pod, 
		version =>  $VERSION,
		apropos => undef,
		faq => undef,
		getopt_data => [] ;
		
		sub_apps =>
			{
			test_application =>
				{
				description => 'executable',
				run =>
					sub
					{
					my ($self, $command, $arguments) =  @_ ;
					system './test_application ' . join(' ', @{$arguments}) ;
					},
				...
				},
			},
			
		@setup_data,
 		) ;
 
 bless $chained_app, $class ;
 
 $chained_app->parse_command_line() ;
 $chained_app->SUPER::run() ;
 }
 
 #--------------------------------------------------------------------------------- 
 
 package main ;
 
 App::Chained::Test->run(command_line_arguments => \@ARGV) ;

=head1 DESCRIPTION

This module implements  an application front end to other applications. As the B<git> command is a front end 
to many B<git-*> sub commands

=head1 DOCUMENTATION

This module tries to provide the git like front end with the minimum work from you. Your sub commands can be implemented in 
perl scripts, modules or even applications written in other languages. You will not have to derive your sub commands from a class I define
nor will you have to  define specific soubrourines/methods in your sub commands. In a word I tried to keep this module as non-intruisive as 
possible.

Putting a front end to height sub applications took a total of 15 minutes plus another 15 minutes when I decided to have a more advanced command
completion. More on completion later.

=head2 What you gain

The Wrapper will handle the following options

=over 2

=item * --help

=item * --apropos

=item * --faq

=item * --version

=item * --generate_bash_completion

=back

=head3 Defining sub commands/applications

 sub_apps =>
  {
  check => # the name of the sub command, it can be an alias
	{
	description => 'does a check', # description
	run => 
  	  sub
	  {
	  # a subroutine reference called to run the sub command
	  # This is a simple wrapper. You don't have to change your modules or scripts
	  # or inherite from any class
			
	  my ($self, $command, $arguments) =  @_ ;
	  system 'your_executable ' . join(' ', @{$arguments}) ;
	  },
			
	help => sub {system "your_executable --help"}, # a sub to be run when help required
	apropos => [qw(verify check error test)], # a list of words to match a user apropos query
	
	options => sub{ ...}, # See generate_bash_completion below
	},
  ...
  }
			
=head1 EXAMPLE

L<App::Requirement::Arch> (from version 0.02) defines a front end application B<ra> to quite a few sub commands. Check the source
of the B<ra> script for a real life example with sub command completion script.

=head1 THIS CLASS USES EXIT!

Some of the default handling will result in this module using B<exit> to return from the application wrapper. I may remove the B<exit> in future
versions as I rather dislike the usage of B<exit> in module.

=head1 SUBROUTINES/METHODS

=cut


#-------------------------------------------------------------------------------

Readonly my $NEW_ARGUMENTS => [qw(NAME INTERACTION help getopt_data sub_apps command_line_arguments version apropos faq usage)] ;

sub new
{

=head2 new(NAMED_ARGUMENT_LIST)

Create a App::Chained object, refer to the synopsis for a complete example.

I<Arguments>

=over 2 

=item *  INTERACTION -  Lets you redefine how B<App::Chained> displays information to thhe user

=item * command_line_arguments - Array reference- 

=item * help - A sub reference -

you can also \&App::Chained::get_help_from_pod if you want your help to be extracted from the pod  present in your app. The pod will be displayed
by I<perldoc> if present in your system or converted by B<App::Chained>.

=item * version - A scalar or a Sub reference -

=item * apropos - A sub reference - 

if it is not defined, The apropos fields in the sub commands entries are searched for a match

=item *  faq - A sub reference - called when the user 

=item * getopt_data - Ans array reference containing 

=over 2

=item * A string - a Getopt specification

=item * A scalar/array/hash/sub reference according to Getop

=item * A string - short description 

=item * A string - long description 

=back

	['an_option|o=s' => \my $option, 'description', 'long description'],

=item * sub_apps - A Hash reference - contains a sub command/application definition

	{
	check =>
		{
		description => 'does a check',
		run =>
			sub
			{
			my ($self, $command, $arguments) =  @_ ;
			system 'ra_check.pl ' . join(' ', @{$arguments}) ;
			},
			
		help => sub {system "ra_check.pl --help"},
		apropos => [qw(verify check error test)],
		options => sub{ ...},
		},
	},

=back

I<Returns> - An App::Chained object

I<Exceptions> - Dies if an invalid argument is passed

=cut

my ($invocant, @setup_data) = @_ ;

my $class = ref($invocant) || $invocant ;
confess 'Error: Invalid constructor call!' unless defined $class ;

my $object = {} ;

my ($package, $file_name, $line) = caller() ;
bless $object, $class ;

$object->Setup($package, $file_name, $line, @setup_data) ;

return($object) ;
}

#-------------------------------------------------------------------------------

sub Setup
{

=head2 [P]Setup

Helper sub called by new.

=cut

my ($self, $package, $file_name, $line, @setup_data) = @_ ;

croak "Error: Invalid number of argument '$file_name, $line'."  if (@setup_data % 2) ;

$self->{INTERACTION}{INFO} ||= sub {print @_} ;
$self->{INTERACTION}{WARN} ||= \&Carp::carp ;
$self->{INTERACTION}{DIE}  ||= \&Carp::croak ;
$self->{NAME} = 'Anonymous';
$self->{FILE} = $file_name ;
$self->{LINE} = $line ;

$self->CheckOptionNames($NEW_ARGUMENTS, @setup_data) ;

%{$self} = 
	(
	NAME                   => 'Anonymous',
	FILE                   => $file_name,
	LINE                   => $line,
	@setup_data,
	) ;

my $location = "$self->{FILE}:$self->{LINE}" ;

$self->{INTERACTION}{INFO} ||= sub {print @_} ;
$self->{INTERACTION}{WARN} ||= \&Carp::carp ;
$self->{INTERACTION}{DIE}  ||= \&Carp::confess ;

if($self->{VERBOSE})
	{
	$self->{INTERACTION}{INFO}('Creating ' . ref($self) . " '$self->{NAME}' at $location.\n") ;
	}

return 1 ;
}

#-------------------------------------------------------------------------------

sub CheckOptionNames
{

=head2 [P]CheckOptionNames

Verifies the named options passed to the members of this class. Calls B<{INTERACTION}{DIE}> in case
of error.

=cut

my ($self, $valid_options, @options) = @_ ;

$self->{INTERACTION}{DIE}->('Invalid number of argument!') if (@options % 2) ;

if('HASH' eq ref $valid_options)
	{
	# OK
	}
elsif('ARRAY' eq ref $valid_options)
	{
	$valid_options = {map{$_ => 1} @{$valid_options}} ;
	}
else
	{
	$self->{INTERACTION}{DIE}->("Invalid argument '$valid_options'!") ;
	}

my %options = @options ;

for my $option_name (keys %options)
	{
	unless(exists $valid_options->{$option_name})
		{
		$self->{INTERACTION}{DIE}->
				(
				"$self->{NAME}: Invalid Option '$option_name' at '$self->{FILE}:$self->{LINE}'\nValid options:\n\t"
				.  join("\n\t", sort keys %{$valid_options}) . "\n"
				);
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

sub parse_command_line
{

=head2 [P]parse_command_line()

Parses the option passed in the throught the named argument B<command_line_arguments>.  It will also handle some 
of the options directly, eg: --help, --apropos, ...

I<Arguments> - None

I<Returns> - Nothing

B<$self->{parsed_command}> is set to the command to run.

B<$self->{command_options}> is set to the options that are to be passed to the command

I<Exceptions> -Dies if an invalid command is passed in the options, warns if the options seem incorrect

=cut

my ($self) = @_ ;

my @command_line_arguments = @{$self->{command_line_arguments}} ;

if(@command_line_arguments)
	{
	local @ARGV = @command_line_arguments ;
	
	my @option_definitions = $self->get_options_definitions() ;
	GetOptions(@option_definitions);
	
	my @arguments_left_on_command_line = @ARGV ;
	
	my $command = shift @arguments_left_on_command_line ;
	my $options_ok = defined $command ? $command !~ /^-/sxm : 0 ;
	
	if($options_ok)
		{
		$self->{parsed_command} = $command ;
		$self->{command_options} = \@arguments_left_on_command_line ;
		}
		
	# run help, faq apropos, ... even if the command line was wrong
					
					
	if(${$self->{getopt_definitions}{h}} ||  ${$self->{getopt_definitions}{help}})
		{
		if(defined $command)
			{
			my $command_index = first_index {/$command/} @{$self->{command_line_arguments}} ;
			my $help_index = first_index {/-(h|help)/} @{$self->{command_line_arguments}} ;
			
			if($command_index < $help_index)
				{
				# the --help comes after the command. let the command handle it
				$self->run_help_command($command) ;
				exit(0) ;
				}
			else
				{
				$self->display_help() ;
				exit(0) ;
				}
			}
		else
			{
			$self->display_help() ;
			exit(0) ;
			}
		}
		
	if(${$self->{getopt_definitions}{version}})
		{
		$self->display_version() ;
		exit(0) ;
		}
		
	if(${$self->{getopt_definitions}{'apropos=s'}})
		{
		$self->display_apropos() ;
		exit(0) ;
		}
		
	if(${$self->{getopt_definitions}{'faq=s'}})
		{
		$self->display_faq() ;
		exit(0) ;
		}
		
	if($options_ok)
		{
		if($command eq 'help')	
			{
			$self->run_help_command($self->{command_options}[0]) ;
			exit(0) ;
			}
		else
			{
			my $sub_apps = $self->{sub_apps} ;
			
			if(defined $sub_apps)
				{
				unless(exists $sub_apps->{$command})
					{
					$self->{INTERACTION}{DIE}("Error: Unrecognized command '$command'\n\n" .  $self->get_command_list()  . "\n\n") ;
					}
				}
			else
				{
				$self->{INTERACTION}{INFO}('No sub applications registred') ;
				}
			}
		}
	else
		{
		if(defined $command)
			{
			$self->{INTERACTION}{WARN}("Error: Invalid or incomplete command '$command'\n") ;
			$self->display_help() ;
			exit(1) ;
			}
		else
			{
			$self->display_usage() ;
			$self->display_command_list() ;
			}
		}
	}
else
	{
	$self->display_usage() ;
	$self->display_command_list() ;
	}

return ;
}

#-------------------------------------------------------------------------------

sub get_options_definitions
{

=head2 [P]get_options_definitions()

Generated an option definition suitable for Getopt::Long. Adding default options is necessary. The added
option will be added in B<$self->{getopt_data}>.

I<Arguments> - None

I<Returns> - a list of tuples

=over 2

=item * first element is a Getopt::Long option defintion

=item * second element is a reference to a scalar (or other type) which will store the option value

I<Exceptions> - None

=cut

my ($self) = @_ ;

my %option_definitions = ## no critic (BuiltinFunctions::ProhibitComplexMappings)
	map 
		{
		my($option_specification, $recipient) = @{$_} ;
		
		my ($type) =  $option_specification =~ m/(=.)$/sxm ;
		$type ||= $EMPTY_STRING ;
		
		$option_specification =~ s/(=.)$//sxm ;
		
		my @options ;
		
		for my $option (split /\|/sxm, $option_specification)
			{
			push @options, "$option$type" => $recipient ;
			}
		
		@options ;
		} @{$self->{getopt_data}} ;


# add help,version, apropos, faq, ... if necessary	
for my $default_option
	(
	['h', \my $help],
	['help', \my $help_long],
	['version', \my $version],
	['apropos=s', \my $apropos],
	['faq=s', \my $faq],
	['generate_bash_completion', sub {$self->generate_bash_completion()}],
	['bash', sub {$self->generate_bash_completion()}],
	)
	{
	my ($option_specification, $recipient) = @{$default_option} ;
	
	unless (exists $option_definitions{$option_specification}) 
		{
		push @{$self->{getopt_data}}, [$option_specification, $recipient, "App::Chained generated '$option_specification' option", $EMPTY_STRING]  ;
		$option_definitions{$option_specification} =  $recipient ;
		}
	}

$self->{getopt_definitions} = \%option_definitions ;

return map {@{$_}[0 .. 1]} @{$self->{getopt_data}} ;
}

#-------------------------------------------------------------------------------

sub display_help
{

=head2 [P]display_help()

Will use B<$self->{help}>, that you set during construction, or will inform you if you haven't set the B<help> field.

I<Arguments> - None

I<Returns> - Nothing

I<Exceptions> - None

=cut

my ($self) = @_ ;

my $help = $self->{help} ;

if(defined $help)
	{
	if('CODE' eq ref $help)
		{
		$help->($self) ;
		}
	else
		{
		if($SCALAR eq ref $help)
			{
			$self->{INTERACTION}{INFO}($help) ;
			}
		}
	}
else
	{
	my $app = ref($self)  ;
	$self->{INTERACTION}{INFO}("No help defined. Please define one in '$app'.\n\n") ;
	}

return ;
}

sub get_help_from_pod
{
use Pod::Text ;

open my $fh, '<', $PROGRAM_NAME or die "Can't open '$PROGRAM_NAME': $!\n";
open my $out, '>', \my $textified_pod or die "Can't redirect to scalar output: $!\n";

Pod::Text->new (alt => 1, sentence => 0, width => 78)->parse_from_filehandle($fh, $out) ;

print $textified_pod ;

exit(1) ;
}

#-------------------------------------------------------------------------------

sub display_usage
{

=head2 [P]display_usage()

Will use B<$self->{usage}>, that you set during construction, or will inform you if you haven't set the B<help> field.

I<Arguments> - None

I<Returns> - Nothing

I<Exceptions> - None

=cut

my ($self) = @_ ;

my $usage = $self->{usage} ;

if(defined $usage)
	{
	if('CODE' eq ref $usage)
		{
		$usage->($self) ;
		}
	else
		{
		if($SCALAR eq ref $usage)
			{
			$self->{INTERACTION}{INFO}($usage) ;
			}
		}
	}
else
	{
	my $app = ref($self)  ;
	$self->{INTERACTION}{WARN}("No usage example. Please define one in '$app'.\n\n") ;
	}

return ;
}

#-------------------------------------------------------------------------------

sub display_command_list
{

=head2 [P]display_command_list()

Will display the list of the sub commands.

I<Arguments> - None

I<Returns> - Nothing

I<Exceptions> - None

=cut

my ($self) = @_ ;

my $commands = $self->get_command_list() ;

$self->{INTERACTION}{INFO}($commands) ;

return ;
}


sub get_command_list
{

=head2 [P]get_command_list()

I<Arguments> - None

I<Returns> - A string -  the list of sub commands

I<Exceptions> - None

=cut

my ($self) = @_ ;

my $sub_apps = $self->{sub_apps} ;

my $commands = $EMPTY_STRING ;

if(defined $sub_apps)
	{
	$commands = "Available commands are:\n" ;
	
	for my $sub_app_name (sort keys %{$sub_apps})
		{
		$commands .= sprintf '  %-25.25s ', $sub_app_name ;
		$commands .= $sub_apps->{$sub_app_name}{description} || 'no description!.' ;
		$commands .= "\n" ;
		}
	}
else
	{
	$commands = 'No commands registred' ;
	}

return $commands ;
}

#-------------------------------------------------------------------------------

sub run_help_command
{

=head2 [P]run_help_command(NAMED_ARGUMENT_LIST)

Handle the B<help> command. It will display help for the sub command or for the application if none is given.

 $> my_app help sub_command

I<Arguments> - None

I<Returns> - Nothing

I<Exceptions> Dies if a wrong sub command name is used or if the sub command doesn't define a B<help> sub

=cut

my ($self, $command ) = @_ ;

return unless defined $self->{parsed_command} ; 

if(defined $command)
	{
	my $sub_app = $self->{sub_apps}{$command} ;

	if(defined $sub_app)
		{
		if(exists $sub_app->{help})
			{
			if('CODE' eq ref($sub_app->{help}))
				{
				$sub_app->{help}($self, $sub_app) ;
				}
			else
				{
				$self->{INTERACTION}{DIE}->("Error: sub app '$self->{parsed_command}' help subroutine is not a code reference.") ;
				}
			}
		else
			{
			$self->{INTERACTION}{DIE}->('Error: sub app does not defined a \'help\' subroutine.') ;
			#~ run man page
			}
		}
	else
		{
		$self->{INTERACTION}{DIE}->("Error: No such command '$command'." .  $self->get_command_list() ) ;
		}
	}
else
	{
	$self->display_help() ;
	exit(0) ;
	}
	
return ;
}

#-------------------------------------------------------------------------------

sub run
{

=head2 [P]run()

Runs the sub command parsed on the command line.

I<Arguments> - None

I<Returns> - Nothing

I<Exceptions> Dies if the sub command B<run> field is improperly set.

=cut

my ($self) = @_ ;

return unless defined $self->{parsed_command} ;

my $sub_app = $self->{sub_apps}{$self->{parsed_command}} ;

if(defined $sub_app->{run})
	{
	if('CODE' eq ref($sub_app->{run}))
		{
		my @arguments ;
		@arguments = map {"'$_'"} @{$self->{command_options}} if(defined $self->{command_options}) ;
		
		$sub_app->{run}($self, $sub_app, \@arguments) ;
		}
	else
		{
		$self->{INTERACTION}{DIE}->("Error: sub app '$self->{parsed_command}' run subroutine is not a code reference.") ;
		}
	}
else
	{
	$self->{INTERACTION}{DIE}->("Error: sub app '$self->{parsed_command}' run subroutine is not defined.") ;
	}

return ;
}

#-------------------------------------------------------------------------------

sub generate_bash_completion
{
	
=head2 [P]generate_bash_completion()

The generated completion is in two parts:

A perl script used to generate  the completion (output on stdout) and a shell script that you must source (output on stderr).

 $> my_app -bash 1> my_app_perl_completion.pl 2> my_app_regiter_completion

Direction about how to use the completion scritp is contained in the generated script.

The completion will work for the top application till a command is input on the command line after that the completion is for the command.

=head3 command specific options

Your sub commands can define an B<options> field. The field should be set to a subroutine reference that returns a string of options the sub command
accepts. The format should be I<-option_name>. One option perl line.

Here is an example of how I added completion to a set sub commands (8 of them). The sub commands do not have a completion script
and rely on the wrapper for completion. 

I first set the B<options> field:

	{
	description => ...
	run => ...
	...
	
	options => sub {return `$name --dump_options`},
	}

I am using the sub command itself to generate the options. This way I don't have to maintain the list by hand (which is possible).

Modifying the sub command itself was trivial and very quick. I modified the following code (example in one of thesub commands)

  die 'Error parsing options!'unless 
    GetOptions
      (
      'master_template_file=s' => \$master_template_file,
      'h|help' => \&display_help, 
      ) ;
      
to  be

  die 'Error parsing options!'unless 
    GetOptions
        (
        'master_template_file=s' => \$master_template_file,
        'h|help' => \&display_help, 
	
       	'dump_options' => 
	  sub 
	  {
	  print join "\n", map {"-$_"} 
	      qw(
		master_template_file
		help
		) ;
	  exit(0) ;
          },
	) ;

Modfying the height or so scripts took only a few minutes.

Noiw I have command completion for all the sub command. Here is an example:

  nadim@naquadim Arch (master)$ ra show -[tab]
  -format                    -include_loaded_from   -master_categories_file                    
  -help                      -include_not_found     -master_template_file
  -include_categories        -include_statistics    -remove_empty_requirement_field_in_categories
  -include_description_data  -include_type          -requirement_fields_filter_file

The I<show> sub command is two order of magnitude easier to use with completion.

I<Arguments> - None

I<Returns> - Nothing - exits with status code B<1> after emitting the completion script on stdout

I<Exceptions> -  None - Exits the program.

=cut

my ($self) = @_ ;

$self->get_options_definitions() ; # generates $self->{getopt_definitions}
my @options = map { s/=.$//sxm ;  "\t-$_ => 0," } keys %{$self->{getopt_definitions}} ;

my @command_options ;
my $sub_apps = $self->{sub_apps} ;

if(defined $sub_apps)
	{
	while(my ($sub_app_name, $sub_app) = each  %{$sub_apps})
		{
		my @sub_app_options ;
		
		if(exists $sub_app->{options} && 'CODE' eq ref($sub_app->{options}))
			{
			@sub_app_options= map {chomp ; $_} $sub_app->{options}($self, $sub_app, []) ;
			}
			
		push @command_options, "\t$sub_app_name =>  [qw(@sub_app_options)]," ;
		}
	}

use File::Basename ;
my ($basename, $path, $ext) = File::Basename::fileparse($PROGRAM_NAME, ('\..*')) ;
my $application_name =  $basename . $ext ;

local $| = 1 ;

my $complete_script =  <<"COMPLETION_SCRIPT" ;

#The perl script has to be executable and somewhere in the path.                                                         
#This script was generated using used your application name

#Add the following line in your I<~/.bashrc> or B<source> them:

_${application_name}_perl_completion()
{                     
local old_ifs="\${IFS}"
local IFS=\$'\\n';      
COMPREPLY=( \$(${application_name}_perl_completion.pl \${COMP_CWORD} \${COMP_WORDS[\@]}) );
IFS="\${old_ifs}"                                                       

return 1;
}        

complete -o default -F _${application_name}_perl_completion $application_name
COMPLETION_SCRIPT

print {*STDERR} $complete_script ;

print {*STDOUT} <<'COMPLETION_SCRIPT' ;
#! /usr/bin/perl                                                                       

=pod

I<Arguments> received from bash:

=over 2

=item * $index - index of the command line argument to complete (starting at '1')

=item * $command - a string containing the command name

=item * \@argument_list - list of the arguments typed on the command line

=back

You return possible completion you want separated by I<\n>. Return nothing if you
want the default bash completion to be run which is possible because of the <-o defaul>
passed to the B<complete> command.

Note! You may have to re-run the B<complete> command after you modify your perl script.

=cut

use strict;
use Tree::Trie;

my ($argument_index, $command, @arguments) = @ARGV ;

$argument_index-- ;
my $word_to_complete = $arguments[$argument_index] ;

my %top_level_completions = # name => takes a file 0/1
	(	
COMPLETION_SCRIPT

print {*STDOUT}  join("\n", @options) . "\n" ;
	
print {*STDOUT} <<'COMPLETION_SCRIPT' ;
	) ;
		
my %commands_and_their_options =
	(
COMPLETION_SCRIPT

print {*STDOUT} join("\n", @command_options) . "\n" ;

print {*STDOUT} <<'COMPLETION_SCRIPT' ;
	) ;
	
my @commands = (sort keys %commands_and_their_options) ;
my %commands = map {$_ => 1} @commands ;
my %top_level_completions_taking_file = map {$_ => 1} grep {$top_level_completions{$_}} keys %top_level_completions ;

my $command_present = 0 ;
for my $argument (@arguments)
	{
	if(exists $commands{$argument})
		{
		$command_present = $argument ;
		last ;
		}
	}

my @completions ;
if($command_present)
	{
	# complete differently depending on $command_present
	push @completions, @{$commands_and_their_options{$command_present}}  ;
	}
else
	{
	if(defined $word_to_complete)
		{
		@completions = (@commands, keys %top_level_completions) ;
		}
	else
		{
		@completions = @commands ;
		}
	}

if(defined $word_to_complete)
        {
	my $trie = new Tree::Trie;
	$trie->add(@completions) ;

        print join("\n", $trie->lookup($word_to_complete) ) ;
        }
else
	{
	my $last_argument = $arguments[-1] ;
	
	if(exists $top_level_completions_taking_file{$last_argument})
		{
		# use bash file completiong or we could pass the files ourselves
		#~ use File::Glob qw(bsd_glob) ;
		#~ print join "\n", bsd_glob('M*.*') ;
		}
	else
		{
		print join("\n", @completions)  unless $command_present ;
		}
	}

COMPLETION_SCRIPT

exit(0) ;
}

#-------------------------------------------------------------------------------

sub display_version
{

=head2 [P]display_version()

Displays the version you set through  B<$self->{version}>.

I<Arguments> - None

I<Returns> - Nothing

I<Exceptions> None. Will warn if you forgot to set a version

See C<xxx>.

=cut

my ($self) = @_ ;

my $version = $self->{version} ;

if(defined $version)
	{
	if('CODE' eq ref $version)
		{
		$version->($self) ;
		}
	else
		{
		if($SCALAR eq ref $version)
			{
			$version .= "\n" unless $version =~ /\n$/sxm ;
			
			$self->{INTERACTION}{INFO}($version) ;
			}
		}
	}
else
	{
	my $app = ref($self)  ;
	$self->{INTERACTION}{WARN}("No version. Please define one in '$app'.\n\n") ;
	}

return ;
}

#-------------------------------------------------------------------------------

sub display_apropos
{

=head2 [P]display_apropos()

Will display matches to the apropos query using B<$self->{apropos}>, that you set during construction, or will search in the
B<apropos> field of the sub commands.

I<Arguments> - None - takes the search string from the I<--apropos> option.

I<Returns> - Nothing

I<Exceptions> - None

=cut

my ($self) = @_ ;

my $apropos = $self->{apropos} ;

my $apropos_option = ${$self->{getopt_definitions}{'apropos=s'}} ;

if(defined $apropos)
	{
	if('CODE' eq ref $apropos)
		{
		$apropos->($self, $apropos_option) ;
		}
	else
		{
		if($SCALAR eq ref $apropos)
			{
			$apropos .= "\n" unless $apropos =~ /\n$/sxm ;
			
			$self->{INTERACTION}{INFO}($apropos) ;
			}
		}
	}
else
	{
	my $sub_apps = $self->{sub_apps} ;
	
	if(defined $sub_apps)
		{
		my $command ;
		
		for my $sub_app_name (sort keys %{$sub_apps})
			{
			if(any {/\Q$apropos_option/sxm} @{$sub_apps->{$sub_app_name}{apropos}})
				{
				$command .= sprintf '    %-25.25s ', $sub_app_name ;
				$command .= $sub_apps->{$sub_app_name}{description} || 'no description!.' ;
				$command .= "\n" ;
				}
			}
			
		defined $command 
			? $self->{INTERACTION}{INFO}("Matching apropos search:\n$command") 
			: $self->{INTERACTION}{INFO}("No match for apropos search.\n")  ;
		}
	else
		{
		$self->{INTERACTION}{INFO}('No sub applications registred') ;
		}
	}

return ;
}

#-------------------------------------------------------------------------------

sub display_faq
{

=head2 [P]display_faq()

Will display an answer to a a faq question using  B<$self->{faq}>, that you set during construction, or will inform you if you haven't set the B<faq> field.

I<Arguments> - None - takes the FAQ query from the I<--faq> option.

I<Returns> - Nothing

I<Exceptions> - None

=cut

my ($self, @argument) = @_ ;

my $faq = $self->{faq} ;

my $faq_option = ${$self->{getopt_definitions}{'apropos=s'}} ;

if(defined $faq)
	{
	if('CODE' eq ref $faq)
		{
		$faq->($self, $faq_option) ;
		}
	else
		{
		if($SCALAR eq ref $faq)
			{
			$faq .= "\n" unless $faq =~ /\n$/sxm ;
			
			$self->{INTERACTION}{INFO}($faq) ;
			}
		}
	}
else
	{
	my $app = ref($self)  ;
	$self->{INTERACTION}{WARN}("No FAQ. Please define one in '$app'.\n\n") ;
	}

return ;}

#-------------------------------------------------------------------------------

1 ;

=head1 BUGS AND LIMITATIONS

None so far.

=head1 AUTHOR

	Nadim ibn hamouda el Khemir
	CPAN ID: NKH
	mailto: nadim@cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright Nadim Khemir 2010.

This program is free software; you can redistribute it and/or
modify it under the terms of either:

=over 4

=item * the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any
later version, or

=item * the Artistic License version 2.0.

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Chained

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Chained>

=item * RT: CPAN's request tracker

Please report any bugs or feature requests to  L <bug-app-chained@rt.cpan.org>.

We will be notified, and then you'll automatically be notified of progress on
your bug as we make changes.

=item * Search CPAN

L<http://search.cpan.org/dist/App-Chained>

=back

=head1 SEE ALSO


=cut
