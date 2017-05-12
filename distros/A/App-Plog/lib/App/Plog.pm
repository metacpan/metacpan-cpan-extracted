
## no critic (Modules::ProhibitMultiplePackages)
## no critic (BuiltinFunctions::ProhibitStringyEval)
## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars) 

package main ;

use strict;
use warnings ;
use Carp qw(carp croak confess) ;
use English qw( -no_match_vars ) ;
use Readonly ;

sub run_ipc3
{	
my ($command, $error_message) = @_ ;

Readonly my $CHILD_ERROR_SHIFT => 8 ;

use IPC::Open3 ;
use Symbol 'gensym'; 

my($in, $out, $err) ;
$err = gensym() ;

my $pid = open3($in, $out, $err, $command) ;
waitpid( $pid, 0 );

if ($CHILD_ERROR >> $CHILD_ERROR_SHIFT)
	{
	croak "Error: can't execute '$command' $error_message: $CHILD_ERROR\n" ;
	}

# todo: check wantarray
my $text = do { local $INPUT_RECORD_SEPARATOR = undef ; <$out> ; } ;

return $text ;
}

package App::Plog ;

use strict;
use warnings ;
use Carp qw(carp croak confess) ;

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
$VERSION     = '0.01';
}

#-------------------------------------------------------------------------------

use English qw( -no_match_vars ) ;
use Readonly ;
Readonly my $EMPTY_STRING => q{} ;

use File::HomeDir ;
use Getopt::Long ;
use English qw( -no_match_vars ) ;
use File::Temp qw/tempdir/ ;
use File::Path ;
use File::Copy::Recursive qw/rcopy/ ;

#-------------------------------------------------------------------------------

=head1 NAME

App::Plog - The one and a half minute blog

=head1 SYNOPSIS

 use App::Plog ;
 
 App::Plog::create_blog(@ARGV) ;
 
 exit(0)  ;

=head1 DESCRIPTION

Generate a rudimentary HTML blog.

=head1 DOCUMENTATION

This module installs a script that allow you to generate a rudimentary blog using your prefered editor and the command line. 
This file documents the inner workings of the module.

Further documentation, useful to the user is displayed by running the I<plog> end user application:

 $> plog --help

=head1 ARCHITECTURAL OVERVIEW

B<App::Plog> purpose is to transform input blocks, in a well defined format, to HTML snippets that are aggregated to form
a single HTML file blog you can publish. The application itself is very simple as it delegates almost every action it takes to 
specialized modules. The modules can be completely replaced or inherited from to tune them.

The default modules used by B<App::Plog> are all defined inline within the B<App::Plog> module. This document describes
the working of those default modules.

=head2 Overview

 ******************     .-----------------------.
 *      RCS       *     |  Extension matching   |
 ******************     |-----------------------|
 * .-------.      *     |   .--------------.    |   .----------.   ************
 * | .-------.    *     |   | pod renderer |    |   | .----------. *   HTML   *
 * '-| .-------.  *  .->|   '--------------'    |-->| | rendered | * template *
 *   '-| entry |  *  |  | .-------------------. |   '-|  entry   | ************
 *     '-------'  *  |  | | Asciidoc renderer | |     '----------'       |
 ******************  |  | '-------------------' |           |            |
          |          |  '-----------------------'           |            |
          v          |                                      |            |
    .-----------.    |                                      |            |
    | .-----------.  |                                      v            v
    | | raw data  |  |   .----------------------.   .-----------------------.
    | |    +      |--'-->|    feed generator    |   |      aggregator       |
    '-| RCS data  |      '----------------------'   '-----------------------'
      '-----------'                  |                          |
                                     |                          |
                                     |                          |
 **************************   .------|--------------------------|-------.
 *     blog elements      *   |      |       tmp directory      |       |
 **************************   |------|--------------------------|-------|
 * .-------.   .-----.    *   |      v                          v       |
 * | image |.  | css |    *   | .----------.              .-----------. |
 * '-------'|  '-----'--. *   | | feed.xml |              | blog.html | |
 *  '-------'     | ... | *   | '----------'              '-----------' |
 *                '-----' *   |                                         |
 **************************   '-----------------------------------------'
              |                                    |
              |                                    |      ********************
              |       .-------------------.        |      * note: input data *
              '------>| publishing script |<-------'      *  is in box with  *
                      '-------------------'               *    star border   *
                                                          ********************

=head2 Blog configuration

Each blog has a specific configuration which allows you to fine tune the default behavior or override it. The elements used by 
B<App::Plog> are defined within the blog configuration file so you can use your own modules or specialize the default modules.

The blog configuration is a perl data structure looking like:

 {
 commands =>
  {
  class => 'App::Plog::Commands',
  },
  
 rcs =>
  {
  class => 'App::Plog::RCS::Git',
  entry_directory => '/where/the/blogs/entries/git/repository/is',
  },
 
 renderer =>
  {
  class => 'App::Plog::Renderer::Extension',
     
  renderers =>
   {
   # match the entry file extension to the specialized renderer
   # using perl regex
   '.pod$' =>
    {
    class => 'App::Plog::Renderer::HTML::Pod',
    css => 'sco.css' # make it look like search.cpan.org
    },
   '.txt$' =>
    {
    class => 'App::Plog::Renderer::HTML::Asciidoc',
    },
   '.' => # default to pod
    {
   class => 'App::Plog::Renderer::HTML::Pod',
   css => 'sco.css'
   },
  },
 },
 
 aggregator =>
  {
  class => 'App::Plog::Aggregator::Template::Inline',
  
  # information passed to the Aggregator
  template => 'frame.html',
  feed_tag => 'FEED_TAG',
  entries_tag => 'ENTRIES_TAG',
  result_file => 'plog.html',
  },
 
 feed =>
  {
  class => 'App::Plog::Feed::Atom',
  page => 'http://your_server/your_blog/your_plog.html', 
  } ,
	
 # used in the update sub
 destination_directory => '/some/directory/to/publish/your_blog/in',
 
 #relative to blog root directory, can contain css, images, ...
 elements_directory => 'elements', 
 
 update_script => 
  'update_blog.pl', # or shell script, bat file, ...
  # or
  sub
   {
   my ($configuration, $blog_directory, $temporary_directory) = @_ ;
   
   my $elements_directory 
     = "$blog_directory/$configuration->{elements_directory}/*" ;
   
   ...
   
   },
 }

=head2 Commands

The default commands are defined within the B<App::Plog::Commands> package. You can add or remove commands from
the I<plog> application by deriving from B<App::Plog::Commands> or writing a new module.

=head2 Revision control system

The default RCS is B<git>. B<App::Plog::RCS::Git> implements the interface needed by B<App::Plog>. Other RCS
are possible as well as a plain file system backend. I'll be happy to add another RCS to the distribution.

=head2 Renderers

Transform input blocks to HTML snippets is handled, at the top level, by L<App::Plog::Renderer::Extension>.
L<App::Plog::Renderer::Extension> doesn't render the input blocks directly; it matches the input block file
extension to a specialized renderer and runs it. See section L<renderer> in the configuration.

Two input formats are supported in the distribution, B<Pod> and B<Asciidoc>. Other format can easily be added.

=head2 Agregator

The default aggregator is implemented in B<App::Plog::Aggregator::Template::Inline>. B<App::Plog::Aggregator::Template::Inline>
simply replaces user defined I<tags> with the rendered HTML snippets in a template of you choosing. The template
and tags are defined in the configuration in section I<aggregator>.

=head2 Feed

If  section I<feed> is defined, the feed generator, Package B<App::Plog::Feed::Atom> in the default configuration,
generates an Atom feed file. The aggregator also checks for the generation of a feed and inserts a feed link and
icon in the template.

=head2 Publishing the blog

The blog is published, made available to people other than the author, or just the author if you so wish, by a user
defined script or perl sub defined in the blog configuration.

=head1 SUBROUTINES/METHODS

The subroutines and methods are listed below for each package

=head1 App::Plog  SUBROUTINES/METHODS 

=cut

#-------------------------------------------------------------------------------

sub create_blog
{

=head2 create_blog(@arguments)

I<create_blog> will parse the command line and execute the the I<plog> command.

 use App::Plog ;
 App::Plog::create_blog(@ARGV) ;
 exit(0) ;

I<Arguments>

=over 2 

=item * @arguments - the arguments passed on the command line

=back

I<Returns> - Nothing

I<Exceptions> - Croaks on bad commands

=cut

my (@arguments) = @_ ;

my ($command, $arguments, $configuration, $blog_id, $blog_directory, $blog_configuration_file, $blog_configuration, $temporary_directory)
	= parse_configuration(@arguments) ;

my $command_handler = eval q~$blog_configuration->{commands}{class}->new($blog_configuration->{commands})~ ; 
croak $EVAL_ERROR if $EVAL_ERROR ;

$command_handler->run_command
	(
	$command,
	$arguments, $configuration, $blog_id, $blog_directory, $blog_configuration_file, $blog_configuration, $temporary_directory
	) ;

return ;
}

#-------------------------------------------------------------------------------

sub parse_configuration
{

=head2 parse_configuration(@arguments)

 my ($command, $arguments, $configuration, $blog_id, $blog_directory, $blog_configuration_file, $blog_configuration, $temporary_directory)
	= parse_configuration(@arguments) ;

The global I<plog> configuration is located in I<~:.plog> but can be overridden by the I<--configuration_path> option. 
I<Arguments>

=over 2 

=item * @arguments - command line arguments passed to the I<plog> script in the format

 $> plog [--option[s]] command [argument] [argument] ...

=back

I<Returns> 

=over 2 

=item * $command - the command  to execute

=item * \@arguments - the arguments to the command to execute

=item * \%configuration -  the global plog configuration

=item * $blog_id - the name of the blog to work on. extracted from the global configuration or passed
through the I<--blog_id> option

=item * $blog_directory - the directory where the '$blog_id' data are

=item * $blog_configuration_file -  the file name of the '$blog_id' configuration

=item * \%blog_configuration - the '$blog_id' plog configuration

=item * $temporary_directory - a temporary directory created during the run of the script or the 
directory passed thought the I<--temporary_directory> option

=back

I<Exceptions>

=over 2

=item * Invalid options

=item * missing configuration files

=item * errors in configuration files

=back

=cut

my (@arguments) = @_ ;
local @ARGV = @arguments ;

# parse command line
my $blog_id ;
my $configuration_path ;
my $temporary_directory ;

croak 'Invalid option!' unless GetOptions 
			(
			'h|help' => \&display_help,
			'blog_id=s'   => \$blog_id,
			'configuration_path=s'   => \$configuration_path,
			'temporary_directory=s' => \$temporary_directory,
			) ;

$configuration_path = File::HomeDir->my_home()  . "/.plog" unless defined $configuration_path ;

# parse global configuration
my $configuration_file = $configuration_path . '/config.pl' ;
croak "Error: Can't find Plog configuration! ($configuration_file)\n" unless(-e $configuration_file)  ;

my $configuration = do $configuration_file or croak "Error: Can't parse Plog config! ($configuration_file) $EVAL_ERROR\n" ;

$blog_id = $configuration->{default_blog} unless defined $blog_id ;
my $blog_directory = "$configuration->{plog_root_directory}/$blog_id" ;

# parse blog configuration
my $blog_configuration_file = "$blog_directory/config.pl" ;
my $blog_configuration  ;

if(-e $blog_configuration_file)
        {
        $blog_configuration = do $blog_configuration_file or croak "Error: Can't parse blog configuration! ($blog_configuration_file) $EVAL_ERROR\n" ;
        }
else
        {
        croak "Error: Can't find blog '$blog_id' configuration! ($blog_configuration_file)\n" ;
        }

# create temporary directory to work in
$temporary_directory = tempdir( CLEANUP => 1 ) unless defined $temporary_directory ;
mkpath $temporary_directory unless -e $temporary_directory ;
$blog_configuration->{temporary_directory} = $temporary_directory ;

my @files_in_temporary_directory = glob("$temporary_directory/*") ;
carp "Warning: temporary directory '$temporary_directory' is not empty!" if @files_in_temporary_directory ;

my $command = shift @ARGV ;

return($command, [@ARGV], $configuration, $blog_id, $blog_directory, $blog_configuration_file, $blog_configuration, $temporary_directory) ;
}

#-------------------------------------------------------------------------------

sub display_help
{

=head2 display_help()

I<Arguments> - None

I<Returns> - Exits the process with value 0 (zero).

I<Exceptions> - Croaks on perldoc errors

=cut

my ($this_script) = ($PROGRAM_NAME =~m/(.*)/sxm ) ;

print {*STDOUT} `perldoc $this_script`  or croak 'Error: Can\'t display help!' ; ## no critic (InputOutput::ProhibitBacktickOperators)
exit(0) ;
}

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

package App::Plog::Commands ;

=head1 App::Plog::Commands SUBROUTINES/METHODS

=cut

use strict ;
use warnings ;
use Carp ;
use English qw( -no_match_vars ) ;

use File::Copy::Recursive qw/rcopy dircopy/ ;
use IPC::Open3 ;
use Readonly ;

#-------------------------------------------------------------------------------

my %commands =  
	(
	ls => \&ls_entries,
	ls_blogs => \&ls_blogs,
	add  => \&add_entry,
	copy => \&copy_elements,
	generate => \&generate_blog,
	update => \&update_blog,
	) ;
	
#-------------------------------------------------------------------------------

sub new 
{

=head2 new(\%options)

I<Arguments>

=over 2 

=item * \%options - the B<command> section from the blog configuration file

=back

I<Returns> - a App::Plog::Command object

I<Exceptions> -None

=cut

my ($invocant, $options) = @_ ;

my $class = ref($invocant) || $invocant ;
confess 'Invalid constructor call!' unless defined $class ;

my $object = {%{$options}} ;

return bless $object, $class ;
}

#-------------------------------------------------------------------------------

sub command_exists
{

=head2 command_exists(...)

I<Arguments>- string - command name

I<Returns> - boolean -true if the command is available to run

I<Exceptions> - 

=cut

my ($self, $command) = @_ ;

return exists $commands{$command} ;
}

sub run_command
{

=head2 run_command(...)

I<Arguments>- see B<Returns> in sub L<parse_configuration>

I<Returns> - Nothing

I<Exceptions> - command if the command is neither defined nor exists

=cut

my ($self, $command, @arguments) = @_ ;

croak "Error: no command!\n" unless defined $command ;
croak "Error: Unknown command '$command'!\n" unless $self->command_exists($command) ;

$commands{$command}->(@arguments) ;

return ;
}


#-------------------------------------------------------------------------------

sub add_entry  ## no critic (Subroutines::ProhibitManyArgs)
{

=head2 add_entry(...)

For each argument passed to this command, a file will be created in the current directory based on the blog template. A blog template
is a file that matches I<$blog_directory/entry_template*>. The contents are of no importance to I<plog>. 

I<Arguments>- see B<Returns> in sub L<parse_configuration>

I<\@arguments> Contains the list of files to create

I<Returns> - Nothing

I<Exceptions> - Croaks if no template is found or more than a template is found

=cut

my ($arguments, $configuration, $blog_id, $blog_directory, $blog_configuration_file, $blog_configuration, $temporary_directory) = @_ ;

my @templates = glob("$blog_directory/entry_template*" ) ;

#todo: match extension if multiple templates
croak "Error: Found more than one template in '$blog_directory'!\n" if @templates > 1 ;
croak "Error: No name for entry! Usage 'Plog add new_entry_name.ext ...'\n" unless @{$arguments} ;

for (@{$arguments})
	{
	rcopy($templates[0], "./$_") or croak "Error: Can't copy '$templates[0]' to '$_': $!" ;
	}

return ;
}

#-------------------------------------------------------------------------------

sub copy_elements ## no critic (Subroutines::ProhibitManyArgs)
{

=head2 copy_elements(...)

Each argument passed to this command is taken as a file or a directory and will be copied
to <$blog_directory/$blog_configuration->{elements_directory}>. A line, for each argument, is output 
on STDOUT.

I<Arguments>- see B<Returns> in sub L<parse_configuration>

I<\@arguments> Contains the list of files to copy

I<Returns> - Nothing

I<Exceptions> - Croaks if the copy fails

=cut

my ($arguments, $configuration, $blog_id, $blog_directory, $blog_configuration_file, $blog_configuration, $temporary_directory) = @_ ;

my $elements_directory = "$blog_directory/$blog_configuration->{elements_directory}" ;

for (@{$arguments})
	{
	print {*STDOUT} "$_ => $elements_directory/$_\n" ;
	rcopy($_, "$elements_directory/$_") or croak "Error: Can't copy '$_' to '$elements_directory/$_': $!" ;
	}

return ;
}

#-------------------------------------------------------------------------------

sub ls_entries ## no critic (Subroutines::ProhibitManyArgs)
{

=head2 ls_entries()

Lists all the blog entry under version control in I<$blog_configuration->{rcs}{entry_directory}>.

I<Arguments>- see B<Returns> in sub L<parse_configuration>

I<Returns> - Nothing

I<Exceptions> - Croaks if the RCS object can't be created

=cut

my ($arguments,  $configuration, $blog_id, $blog_directory, $blog_configuration_file, $blog_configuration, $temporary_directory) = @_ ;

my $rcs = eval q~$blog_configuration->{rcs}{class}->new($blog_configuration->{rcs})~ ; croak $EVAL_ERROR if $EVAL_ERROR ;
my $entries = $rcs->parse($blog_directory, $temporary_directory) ;

print "$_ ($entries->{$_}[0]{date})\n" for (keys %{$entries}) ;

return ;
}

#-------------------------------------------------------------------------------

sub ls_blogs ## no critic (Subroutines::ProhibitManyArgs)
{

=head2 ls_blogs(...)

Prints, on stdout, the list of blogs available to I<plog>. where a blog is a directory within I<$configuration->{plog_root_directory}/>.

I<Arguments>- see B<Returns> in sub L<parse_configuration>

I<Returns> - Nothing

I<Exceptions>

=cut

my ($arguments, $configuration, $blog_id, $blog_directory, $blog_configuration_file, $blog_configuration, $temporary_directory) = @_ ;

my $root_directory = "$configuration->{plog_root_directory}/*" ;
my @files = glob($root_directory) ;

for my $file (@files)
	{
	print {*STDOUT} substr($file, (length($root_directory) - 1)),  "\t($file)\n" if -d $file ;
	}

return ;
}

#-------------------------------------------------------------------------------

sub generate_blog ## no critic (Subroutines::ProhibitManyArgs)
{

=head2 generate_blog(...)

Handles the creation of the blog and its feed, including the creation of  the objects defined in the I<plog> configuration.

I<Arguments>- see B<Returns> in sub L<parse_configuration>

I<Returns> - Nothing

I<Exceptions> - Croaks if object needed to generate the blog can't be created

=cut

my ($arguments, $configuration, $blog_id, $blog_directory, $blog_configuration_file, $blog_configuration, $temporary_directory) = @_ ;

# create objects
my $rcs = eval q~$blog_configuration->{rcs}{class}->new($blog_configuration->{rcs})~ ; croak $EVAL_ERROR if $EVAL_ERROR ;
my $renderer = eval q~$blog_configuration->{renderer}{class}->new($blog_configuration->{renderer})~ ; croak $EVAL_ERROR if $EVAL_ERROR ;
my $aggregator = eval q~$blog_configuration->{aggregator}{class}->new($blog_configuration->{aggregator})~ ; croak $EVAL_ERROR if $EVAL_ERROR ;

# create blog
my $entries = $rcs->parse($blog_directory, $temporary_directory) ;
my $rendered_entries = $renderer->render($entries, $blog_directory, $temporary_directory) ;
my $aggregated_entries = $aggregator->aggregate($rendered_entries, $blog_directory, $temporary_directory) ;

if(exists $blog_configuration->{feed})
	{
	my $feed_generator = eval q~$blog_configuration->{feed}{class}->new($blog_configuration->{feed})~ ; croak $EVAL_ERROR if $EVAL_ERROR ;
	$feed_generator->generate($rendered_entries, $blog_directory, $temporary_directory) ; 
	}

my $elements_directory = "$blog_directory/$blog_configuration->{elements_directory}/*" ;

# update the temporary directory with blog element to allo the user to check his blog
# without having to update the web page
dircopy($elements_directory, $temporary_directory) or carp $! ;

return ;
}

#-------------------------------------------------------------------------------

sub update_blog ## no critic (Subroutines::ProhibitManyArgs)
{

=head2 update_blog(...)

Generates the blog and runs the update script defined in I<$blog_configuration->{update_script}>. The update
script usually publishes the blog by copying the necessary data to a web server.

The update script is either a script in the language of your choosing, in which case the following arguments are passed 
on the command line

=over 2

=item * $blog_configuration_file  

=item * $blog_directory 

=item * $temporary_directory

=back 

or a perl sub in which case the following arguments are passed to the sub

=over 2

=item * $blog_configuration

=item * $blog_directory 

=item * $temporary_directory

=back 

I<Arguments>- see B<Returns> in sub L<parse_configuration>

I<Returns> - Nothing

I<Exceptions>

=cut

my ($arguments, $configuration, $blog_id, $blog_directory, $blog_configuration_file, $blog_configuration, $temporary_directory) = @_ ;

generate_blog(@_) ;

if('CODE' eq ref $blog_configuration->{update_script})
	{
	$blog_configuration->{update_script}->($blog_configuration,  $blog_directory, $temporary_directory) ;
	}
else
	{
	print {*STDOUT} run_ipc3("$blog_directory/$blog_configuration->{update_script}", 'to get entry text') ; 
	}

return ;
}

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

package App::Plog::RCS::Git ;

=head1 App::Plog::RCS::Git SUBROUTINES/METHODS

=cut

use strict;
use warnings ;
use Carp qw(carp croak confess) ;
use Tie::Hash::Indexed ;
use English  '-no_match_vars';
use Readonly ;

sub new 
{

=head2 new(\%options)

I<Arguments>

=over 2 

=item * \%options - the B<rcs> section from the blog configuration file

=back

I<Returns> - a App::Plog::RCS::Git object

I<Exceptions> -None

=cut

my ($invocant, $options) = @_ ;

my $class = ref($invocant) || $invocant ;
confess 'Invalid constructor call!' unless defined $class ;

my $object = {%{$options}} ;

return bless $object, $class ;
}

#-------------------------------------------------------------------------------

sub parse
{

=head2 parse($self, $blog_directory, $temporary_directory)

I<Arguments>

=over 2 

=item * $self - 

=item * $blog_directory - the path to the blog directory

=item * $temporary_directory - directory where temporary data can be saved

=back

I<Returns> - Nothing

I<Exceptions>

=cut

my ($self, $blog_directory, $temporary_directory) = @_ ;

# todo: warn if status is not clean

# get the entries, sort them and add some information
my $git_directory = "$self->{entry_directory}/.git" ;

#~ my @rcs_data = `git --git-dir=$git_directory log --name-status --date=iso` ;

my @rcs_data = split /\n/sxm, ::run_ipc3
						(
						"git --git-dir=$git_directory log --name-status --date=iso",
						'to collect data',
						) ;

tie my %entries, 'Tie::Hash::Indexed'; ## no critic (Miscellanea::ProhibitTies)
my ($commit, $date) ;

for (@rcs_data)
        {
        /^commit\s+(.*)/xsm and do
                {
                $commit = $1 ; next ;
                } ;

        /^Date:\s+(.*)/xsm  and do
                {
                $date = $1 ; next ;
                } ;

        (/^(A)\t(.*)/xsm  || /^(M)\t(.*)/xsm)  and do
                {
                my $type = $1 ;
                my $entry_name = $2 ;
		
		my $text = ::run_ipc3("git --git-dir=$git_directory show $commit:$entry_name", 'to get entry text') ; 
		
                push @{$entries{$entry_name}}, {date => $date, commit => "$commit:$entry_name", type => $type, text => $text} ;
                next ;
                } ;
        }

return \%entries ;
}

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

package App::Plog::Renderer::Extension ;

=head1 App::Plog::Renderer::Extension SUBROUTINES/METHODS

=cut

use strict;
use warnings ;
use Carp qw(carp croak confess) ;
use English qw( -no_match_vars ) ;

sub new
{

=head2 new(\%options)

I<Arguments>

=over 2 

=item * \%options - the B<renderer> section from the blog configuration file

=back

I<Returns> - an App::Plog::Renderer::Extension object

I<Exceptions> -None

=cut

my ($invocant, $options) = @_ ;

my $class = ref($invocant) || $invocant ;
confess 'Invalid constructor call!' unless defined $class ;

my $object = {%{$options}} ;

return bless $object, $class ;
}

#-------------------------------------------------------------------------------

sub render
{

=head2 render($self, \%entries, $blog_directory, $temporary_directory)

 exit(0) ;

I<Arguments>

=over 2 

=item * $self - 

=item * \%entries - entries parsed by the rcs object

=item * $blog_directory - the path to the blog directory

=item * $temporary_directory - directory where temporary data can be saved

=back

I<Returns> - Nothing

I<Exceptions>

=cut

my ($self, $entries, $blog_directory, $temporary_directory) = @_ ;

#  renderer the entries. latest commit only
while (my ($entry_name, $entry) = each %{$entries})
        {
	my ($renderer, $renderer_name) ; ;

	for my $regex (keys %{$self->{renderers}})
		{
		if($entry_name =~ $regex)
			{
			# create renderer if necessary
			$renderer_name = $self->{renderers}{$regex}{class} ;
			
			unless (defined $self->{renderers}{$regex}{instance})
				{
				$self->{renderers}{$regex}{instance} =
					eval q~$self->{renderers}{$regex}{class}->new($self->{renderers}{$regex})~ ;

				croak $EVAL_ERROR if $EVAL_ERROR ;
				}
				
			$renderer = $self->{renderers}{$regex}{instance} ;
			last ;
			}
		}

	if(defined $renderer)
		{
		#~ print "rendering '$entry_name' with $renderer_name.\n" ;
		$entry->[0]{HTML} = $renderer->render
							(
							$blog_directory,
							$temporary_directory, 
							scalar(@{$entry}),
							$entry->[-1]{commit},
							$entry->[0]{text},
							$entry->[0]{date},
							) ;
		}
	else
		{
		carp "Error: Can't find renderer for '$entry_name'!\n" ;
		$entry->[0]{HTML} = $EMPTY_STRING ;
		}
        }

return $entries ;
}

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

package App::Plog::Renderer::HTML ;

=head1 App::Plog::Renderer::HTML SUBROUTINES/METHODS

=cut

use strict;
use warnings ;
use Carp qw(carp croak confess) ;

sub new
{

=head2 new()

I<Arguments> - None

I<Returns> - Nothing

I<Exceptions> - confess if called. This class serves a base class to derived classes

=cut

confess 'Error: App::Plog::Renderer::HTML can not be instanciated!' ;
}

#-------------------------------------------------------------------------------

sub get_entry_date_html
{

=head2 get_entry_date_html($self, $date)

I<Arguments>

=over 2 

=item * $self -

=item * $date - string in format "2009-10-05 14:53:24 +0200"

=back

I<Returns> - $date in HTML format in three columns

 2009-10-05
 14:53:24
 +0200 

I<Exceptions> - None

=cut

my ($self, $date) = @_ ;

$date  =~ s/(\d+-\d+-\d+) /$1<br>/gxsm ;
$date  =~ s/(\d+:\d+:\d+) /$1<br>/gxsm ;
$date  =~ s/\s/&nbsp;/gxsm ;

return $date ;
}


#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

package App::Plog::Renderer::HTML::Pod ;
use base 'App::Plog::Renderer::HTML' ;

=head1 App::Plog::Renderer::HTML::Pod SUBROUTINES/METHODS

=cut

use strict;
use warnings ;
use Carp qw(carp croak confess) ;
use Pod::Simple::HTML;

sub new
{

=head2 new(\%options)

I<Arguments>

=over 2 

=item * \%options - the section from the blog configuration file where a  App::Plog::Renderer::HTML::Pod object was required

=back

I<Returns> - an App::Plog::Renderer::HTML::Pod object

I<Exceptions> -None

=cut

my ($invocant, $options) = @_ ;

my $class = ref($invocant) || $invocant ;
confess 'Invalid constructor call!' unless defined $class ;

my $object = {%{$options}} ;

return bless $object, $class ;
}

#-------------------------------------------------------------------------------

sub render
{

=head2 render($self, $blog_directory, $temporary_directory, $version, $commit, $text, $date)

I<Arguments>

=over 2 

=item * $self - 

=item * $blog_directory - the path to the blog directory

=item * $temporary_directory - directory where temporary data can be saved

=item * $version - number - the version  of the blog entry

=item * $commit - the commit id of the blog entry

=item * $text - the text of the entry as it was found by the version control system

=item * $date - string in format "2009-10-05 14:53:24 +0200"

=back

I<Returns> - the pod text rendered to HTML

I<Exceptions> - None

=cut

my ($self, $blog_directory, $temporary_directory, $version, $commit, $text, $date) = @_ ;

open my $input, '<', \$text or croak q{Error: Can't redirect from scalar};
open my $output, '>', \my $html or croak q{Error: Can't redirect to scalar} ;

my $parser = Pod::Simple::HTML->new();
$parser->index(0);
$parser->html_css($self->{css}) ;

$parser->output_fh($output);
$parser->parse_file($input);

my $date_html = $self->get_entry_date_html($date) ;

my $version_html = $version > 1 ? "<br> version: $version" : $EMPTY_STRING ;

my $entry_html = 'Error: App::Plog::Renderer::HTML::Pod found no pod!' ;

if(defined $html && $html =~ m{^.*\Q<!-- start doc -->\E(.*)\Q<!-- end doc -->}xsm)
	{
	$entry_html = $1 ;
	}

$entry_html = <<"EOE" ;
        <tr>
          <td width="100" valign="top"> <font size="1"> <br> $date_html $version_html </td>
 	  <td></td>
         <td width="540"> 
	  	  <a name = '$commit'> </a>
	          $entry_html 
	  </td>
        </tr>
        <td><hr></td><td><hr></td><td><hr></td>

EOE

return $entry_html ;
}

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

package App::Plog::Renderer::HTML::Asciidoc ;

use base 'App::Plog::Renderer::HTML';

=head1 App::Plog::Renderer::HTML::Asciidoc SUBROUTINES/METHODS

=cut

use strict;
use warnings ;
use Carp qw(carp croak confess) ;
use FileHandle;
use English qw( -no_match_vars ) ;
use IPC::Open2 ;

sub new
{

=head2 new(\%options)

I<Arguments>

=over 2 

=item * \%options - the section from the blog configuration file where a  App::Plog::Renderer::HTML::Asciidoc object was required

=back

I<Returns> - an App::Plog::Renderer::HTML::Asciidoc object

I<Exceptions> -None

=cut

my ($invocant, $options) = @_ ;

my $class = ref($invocant) || $invocant ;
confess 'Invalid constructor call!' unless defined $class ;

my $ascii_doc_version = `asciidoc --version` ;
unless($ascii_doc_version =~ s/^.*(asciidoc \d\.\d.*)/$1/)
	{
	$ascii_doc_version = undef ;
	}

my $object = {%{$options}, ascii_doc_version => $ascii_doc_version} ;

return bless $object, $class ;
}

#-------------------------------------------------------------------------------

sub render
{

=head2 render($self, $blog_directory, $temporary_directory, $version, $commit, $text, $date)

I<Arguments>

=over 2 

=item * $self - 

=item * $blog_directory - the path to the blog directory

=item * $temporary_directory - directory where temporary data can be saved

=item * $version - number - the version  of the blog entry

=item * $commit - the commit id of the blog entry

=item * $text - the text of the entry as it was found by the version control system

=item * $date - string in format "2009-10-05 14:53:24 +0200"

=back

I<Returns> - the asciidoc text rendered to HTML

I<Exceptions> - None

=cut

my ($self, $blog_directory, $temporary_directory, $version, $commit, $text, $date) = @_ ;

my $date_html = $self->get_entry_date_html($date) ;

my $version_html = $version > 1 ? "<br> version: $version" : $EMPTY_STRING ;

my ($entry_html, $reader, $writer) = (q{Error: App::Plog::Renderer::HTML::Asciidoc can't run command 'asciidoc'!}) ;

if (defined $self->{ascii_doc_version})
	{
	my $pid = open2($reader, $writer, 'asciidoc -o - -s -' );

	local $INPUT_RECORD_SEPARATOR = undef ;
	print {$writer} $text ; close $writer ;
	$entry_html = <$reader>; close $reader ;
	}

	$entry_html = <<"EOE" ;
	<tr>
	  <td width="100" valign="top"> <font size="1"> <br> $date_html $version_html </td>
	  <td></td>
	  <td width="540"> 
		  <a name = '$commit'> </a>
		  $entry_html 
	  </td>
	</tr>
	<td><hr></td><td><hr></td><td><hr></td>

EOE
	
return $entry_html ;
}

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

package App::Plog::Aggregator::Template::Inline ;

=head1 App::Plog::Aggregator::Template::Inline SUBROUTINES/METHODS

=cut

use strict;
use warnings ;
use Carp qw(carp croak confess) ;
use File::Slurp ;

sub new
{

=head2 new(\%options)

I<Arguments>

=over 2 

=item * \%options - the B<aggregator> section from the blog configuration file

=back

I<Returns> - an App::Plog::Aggregator::Template::Inline object

I<Exceptions> -None

=cut

my ($invocant, $options) = @_ ;

my $class = ref($invocant) || $invocant ;
confess 'Invalid constructor call!' unless defined $class ;

my $object = {%{$options}} ;

return bless $object, $class ;
}

#-------------------------------------------------------------------------------

sub aggregate
{

=head2 aggregate($self, \%entries, $blog_directory, $temporary_directory)

I<Arguments>

=over 2 

=item * $self -

=item * $entries - the entries created by the rcs object and rendered

=item * $blog_directory - the path to the blog directory

=item * $temporary_directory - directory where temporary data can be saved

=back

I<Returns> - Nothing

I<Exceptions> - croaks if template doesn't exist or doesn't contain the tags defined in the configuration.

=cut

my ($self, $entries, $blog_directory, $temporary_directory) = @_ ;

my $html_entries = join "\n", map {$_->[0]{HTML}} values %{$entries};

my $frame = read_file "$blog_directory/$self->{template}" ;

if(exists $self->{feed_tag})
	{
	if	(
		$frame =~ s	{$self->{feed_tag}}
					{<a href="rss.xml">	 <img src="feed-icon-28x28.png"> </a>}xsm
		)
		{
		# replaced feed tag with feed
		}
	else
		{
		croak "Error: Couldn't find feed tag '$self->{feed_tag}' in template!\n" ;
		}
	}
 
if($frame =~ s/$self->{entries_tag}/$html_entries/xsm)
	{
	write_file("$temporary_directory/$self->{result_file}", $frame) ;
	}
else
	{
	croak "Error: Couldn't find entries tag '$self->{entries_tag}' in template!\n" ;
	}

return ;
}

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

package App::Plog::Feed::Atom ;

=head1 App::Plog::Feed::Atom SUBROUTINES/METHODS

=cut

use strict;
use warnings ;
use Carp qw(carp croak confess) ;
use File::Slurp ;
use XML::Atom::SimpleFeed;
use POSIX qw(strftime) ;

sub new
{

=head2 new(\%options)

I<Arguments>

=over 2 

=item * \%options - the B<feed> section from the blog configuration file

=back

I<Returns> - an App::Plog::Feed::Atom object

I<Exceptions> -None

=cut

my ($invocant, $options) = @_ ;

my $class = ref($invocant) || $invocant ;
confess 'Invalid constructor call!' unless defined $class ;

my $object = {%{$options}} ;

return bless $object, $class ;
}

#-------------------------------------------------------------------------------

sub generate
{

=head2 generate($self, $entries, $blog_directory, $temporary_directory)

$temporary_directory/rss.xml


I<Arguments>

=over 2 

=item * $self -

=item * $entries - the entries created by the rcs object and rendered

=item * $blog_directory - the path to the blog directory

=item * $temporary_directory - directory where temporary data can be saved

=back

I<Returns> - Nothing

I<Exceptions> - None

=cut

my ($self, $entries, $blog_directory, $temporary_directory) = @_ ;

my $page = $self->{page} ;
my $now_string = strftime '%Y-%m-%dT%H:%M:%SZ',  localtime() ; 

my $xml_atom_feed = XML::Atom::SimpleFeed->new
			(
			id => 0,
			title   => 'Plog Feed',
			link      => $page, 
			updated => $now_string ,
			author  => 'App::Plog',
			) ;

while(my ($name, $entry) = each %{$entries})
	{
	my $entry_date_string = $entry->[0]{date} ;
	$entry_date_string  =~ s/^\s*(\d+-\d+-\d+)\s*/$1T/xsm ;
	$entry_date_string =~ s/(\d+:\d+:\d+).*/$1Z/xsm ;
	
	$xml_atom_feed->add_entry
		(
		title     => $name, #
		link      => "$page#$entry->[-1]{commit}", 
		id        => $entry->[-1]{commit},
		updated   => $entry_date_string ,
		#~ summary   => 'Summary',
		) ;
	}

write_file("$temporary_directory/rss.xml", $xml_atom_feed->as_string()) ;

return ;
}

#-------------------------------------------------------------------------------

1 ;

=head1 BUGS AND LIMITATIONS

None so far.

=head1 AUTHOR

	Nadim ibn hamouda el Khemir
	CPAN ID: NKH
	mailto: nadim@cpan.org

=head1 COPYRIGHT & LICENSE

Copyright 2009 Nadim Khemir.

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

    perldoc App::Plog

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Plog>

=item * RT: CPAN's request tracker

Please report any bugs or feature requests to  L <bug-app-plog@rt.cpan.org>.

We will be notified, and then you'll automatically be notified of progress on
your bug as we make changes.

=item * Search CPAN

L<http://search.cpan.org/dist/App-Plog>

=back

=head1 SEE ALSO

L<http://search.cpan.org/~dcantrell/Bryar-3.1/lib/Bryar.pm>

L<http://search.cpan.org/~jrockway/Angerwhale-0.062/lib/Angerwhale.pm>

L<http://search.cpan.org/~lgoddard/Blog-Simple-HTMLOnly-0.04/HTMLOnly.pm>

L<http://search.cpan.org/~gilad/Blog-Simple-0.03/Simple.pm>

B<nanoblogger>

=cut
