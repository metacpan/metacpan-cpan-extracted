package App::Framework::Lite ;

=head1 NAME

App::Framework::Lite - A lightweight framework for creating applications

=head1 SYNOPSIS

  use App::Framework::Lite ;
  
  go() ;
  
  sub app
  {
	my ($app, $opts_href, $args_href) = @_ ;
	
	# options
	my %opts = $app->options() ;
    
	# aplication code here....  	
  }


=head1 DESCRIPTION

App::Framework::Lite is a framework for quickly developing application scripts, where the majority of the mundane script setup,
documentation jobs are performed by the framework (under direction from simple text definitions stored in the script). This leaves 
the developer to concentrate on the main job of implementing the application.

The module also provides the facility of embedding itself into a copy of the original script, creating a self-contained stand-alone
script (for further details see L</EMBEDDING>).

Note that this module provides a subset of the the facilities provided by L<App::Framework>, In particular, it provides the L<App::Framework::Features:Args>,   
L<App::Framework::Features:Options>, and L<App::Framework::Features:Data> features.

To jump straight in to developing applications, please see L<App::Framework::Lite::GetStarted>.

=head2 Capabilities

The application framework provides the following capabilities: 

=over 2

=item Options definition

Text definition of options in application, providing command line options, help pages, options checking. 

Also supports variables in options definition, the variables being replaced by other option values, application field values, 
or environment variables.

=item Arguments definition

Text definition of arguments in application, providing command line arguments, help pages, arguments checking, file/directory
creation, file/directory existence, file opening

Also supports variables in arguments definition, the variables being replaced by other argument values, option values, application field values, 
or environment variables.

=item Named data sections

Multiple named __DATA__ sections, the data being readily accessible by name from the application.

Variables can be used in the data definitions, the variables being replaced by command line option values, application field values, 
or environment variables.


=item Application directories

The framework automatically adds the location of the script (following any links) to the Perl search path. This means that perl modules
can be created in subdirectories under the application's script making the application self-contained.

The directories used for loading personalities/extensions/features also include the script install directory, meaning that new personalities/extensions/features
can also be provided with a script. 

=back


=head2 Using This Module 

The minimum you need is:

    use App::Framework::Lite ;

Optionally, you can specify arguments to the underlying features by appending a string to the 'use' pragma. For exanmple:

    use App::Framework::Lite '+Args(open=none)' ;


=head3 Creating Application Object

There are two ways of creating an application object and running it. The normal way is:

    # Create application and run it
    App::Framework::Lite->new()->go() ;

As an alternative, the framework creates a subroutine in the calling namespace called B<go()> which does the same thing:

    # Create application and run it
    go() ;

You can use whatever takes your fancy. Either way, the application object will end up calling the user-defined application subroutines 



=head3 Application Subroutines

Once the application object has been created it can then be run by calling the 'go()' method. go() calls the application's registered functions
in turn:

=over 2

=item * app_start()	

Called at the start of the application. You can use this for any additional set up (usually of more use to extension developers)

=item * app()

Called once all of the arguments and options have been processed

=item * app_end()

Called when B<app()> terminates or returns (usually of more use to extension developers)

=back

The framework looks for these 3 functions to be defined in the script file. The functions B<app_start> and B<app_end> are optional, but it is expected that B<app> will be defined
(otherwise nothing happens!).

=head3 Setup

The application settings are entered into the __DATA__ section at the end of the file. All program settings are grouped under sections which are introduced by '[section]' style headings. There are many 
different settings that can be set using this mechanism, but the framework sets most of them to useful defaults. 

For more details see L</Options> and L</Args>.

=head4 Summary

This should be a single line, concise summary of what the script does. It's used in the terse man page created by pod2man.

=head4 Description

As you'd expect, this should be a full description, user-guide etc. on what the script does and how to do it. Notice that this example
has used one (of many) of the variables available: $name (which expands to the script name, without any path or extension).


=head4 Example

An example script setup is:

    __DATA__
    
    [SUMMARY]
    
    An example of using the application framework
    
    [ARGS]
    
    * infile=f        Input file
    
    Should be set to the input file
    
    * indir=d        Input dir
    
    Should be set to the input dir
    
    [OPTIONS]
    
    -table=s        Table [default=listings2]
    
    Sql table name
    
    -database=s        Database [default=tvguide]
    
    Sql database name
    
    
    [DESCRIPTION]
    
    B<$name> is an example script.


=head2 Args

Args feature that provides command line arguments handling. 

Command line arguments are defined once in a text format and this text format generates both the command line arguments data, but also the man pages, 
help text etc. Defining the expected arguments and their types allows the module to check for the existence of the program arguments and their correctness.

=head3 Argument Definition

Arguments are specified in the application __DATA__ section in the format:

    * <name>=<specification>    <Summary>    <optional default setting>
    
    <Description> 

The parts of the specification are defined below.

=head4 name

The name defines the name of the key to use to access the argument value in the arguments hash. The application framework
passes a reference to the argument hash as the third parameter to the application subroutine B<app> (see L</Script Usage>)

=head4 specification

The specification is in the format:

   [ <direction> ] [ <binary> ] <type> [ <multiple> ]

The optional I<direction> is only valid for file or directory types. For a file or directory types, if no direction is specified then
it is assumed to be input. Direction can be one of: 

=over 4

=item <

An input file or directory

=item >

An output file or directory

=item >>

An output appended file

=back

An optional 'b' after the direction specifies that the file is binary mode (only used when the type is file).

The B<type> must be specified and may be one of:

=over 4

=item f

A file

=item d

A directory

=item s

Any string

=back

Additionally, an optional multiple can be specified. If used, this can only be specified on the last argument. When it is used, this tells the
application framework to use the last argument as an ARRAY, pushing all subsequent specified arguments onto this. Accessing the argument
in the script returns the ARRAY ref containing all of the command line argument values.

Multiple can be:

=over 4

=item '@'

One or more items

=item '*'

Zero or more items. There is also a special case (the real reason for *) where the argument specification is of the form '<f*' (input file multiple). Here, if the script user does not
specify any arguments on the command line for this argument then the framework opens STDIN and provides it as a file handle.  

=back


=head4 summary

The summary is a simple line of text used to summarise the argument. It is used in the man pages in 'usage' mode.

=head4 default

Defaults values are optional. If they are defined, they are in the format:

    [default=<value>]

When a default is defined, if the user does not specify a value for an argument then that argument takes on the defualt value.

Also, all subsequent arguments must also be defined as optional.

=head4 description

The summary is multiple lines of text used to fully describe the option. It is used in the man pages in 'man' mode.

=head3 Feature Options

The Args feature allows control over how it opens files. By default, any input or output file definitions also create equivalent file handles
(the files being opened for read/write automatically). These file handles are made available only in the arguments HASH. The key name for the handle
being the name of the argument with the suffix '_fh'.

For example, the following definition:

    [ARGS]
    
    * file=f		Input file
    
    A simple input directory name (directory must exist)
    
    * out=>f		Output file (file will be created)
    
    An output filename

And the command line arguments:

    infile.txt outfile.txt

Results in the arguments HASH:

    'file'    => 'infile.txt'
    'out'     => 'outfile.txt'
    'file_fh' => <file handle of 'infile.txt'>
    'out_fh'  => <file handle of 'outfile.txt'>

If this behaviour is not required, then you can get the framework to open just input files, output files, or none by using the 'open' option.

Specify this in the App::Framework 'use' line as an argument to the Args feature: 

    # Open no file handles 
    use App::Framework '+Args(open=none)' ;
    
    # Open only input file handles 
    use App::Framework '+Args(open=in)' ;
    
    # Open only output file handles 
    use App::Framework '+Args(open=out)' ;
    
    # Open all file handles (the default)
    use App::Framework '+Args(open=all)' ;

=head3 Variable Expansion

Argument values can contain variables, defined using the standard Perl format:

	$<name>
	${<name>}

When the argument is used, the variable is expanded and replaced with a suitable value. The value will be looked up from a variety of possible sources:
object fields (where the variable name matches the field name) or environment variables.

The variable name is looked up in the following order, the first value found with a matching name is used:

=over 4

=item *

Argument names - the values of any other arguments may be used as variables in arguments

=item *

Option names - the values of any command line options may be used as variables in arguments

=item *

Application fields - any fields of the $app object may be used as variables

=item *

Environment variables - if no application fields match the variable name, then the environment variables are used

=back 



=head2 Script Usage

The application framework passes a reference to the argument HASH as the third parameter to the application subroutine B<app>. Alternatively,
the script can call the app object's alias to the args accessor, i.e. the B<args> method which returns the arguments value list. Yet another
alternative is to call the args accessor method directly. These alternatives are shown below:


    sub app
    {
        my ($app, $opts_href, $args_href) = @_ ;
        
        # use parameter
        my $infile = $args_href->{infile}
        
        # access alias
        my @args = $app->args() ;
        $infile = $args[0] ;
        
        # access alias
        @args = $app->Args() ;
        $infile = $args[0] ;

        ($infile) = $app->args('infile') ;
        
        # feature object
        @args = $app->feature('Args')->args() ;
        $infile = $args[0] ;
    }



=head3 Examples

With the following script definition:

    [ARGS]
    
    * file=f		Input file
    
    A simple input file name (file must exist)
    
    * dir=d			Input directory
    
    A simple input directory name (directory must exist)
    
    * out=>f		Output file (file will be created)
    
    An output filename
    
    * outdir=>d		Output directory
    
    An output directory name (path will be created) 
    
    * append=>>f	Output file append
    
    An output filename (an existing file will be appended; otherwise file will be created)
    
    * array=<f*		All other args are input files
    
    Any other command line arguments will be pushced on to this array. 

The following command line arguments:

    infile.txt indir outfile.txt odir append.txt file1.txt file2.txt file3.txt 

Give the arguments HASH values:

    'file'     => 'infile.txt'
    'file_fh'  => <infile.txt file handle>
    'dir'      => 'indir'
    'out'      => 'outfile.txt'
    'out_fh'   => <outfile.txt file handle>
    'outdir'   => 'odir'
    'append'   => 'append.txt'
    'append_fh'=> <append.txt file handle>
    'array'    => [
    	'file1.txt'
    	'file2.txt'
    	'file3.txt'
    ]
    'array_fh' => [
    	<file1.txt file handle>
    	<file2.txt file handle>
    	<file3.txt file handle>
    ]


An example script that uses the I<multiple> arguments, along with the default 'open' behaviour is:

    sub app
    {
        my ($app, $opts_href, $args_href) = @_ ;
        
        foreach my $fh (@{$args_href->{array_fh}})
        {
            while (my $data = <$fh>)
            {
                # do something ... 
            }
        }
    }    
    
    __DATA__
    [ARGS]
    * array=f@    Input file
    

This script can then be called with one or more filenames and each file will be processed. Or it can be called with no 
filenames and STDIN will then be used.


=head2 Options

Options feature that provides command line options handling. 

Options are defined once in a text format and this text format generates 
both the command line options data, but also the man pages, help text etc.

=head3 Option Definition

Options are specified in the application __DATA__ section in the format:

    -<name><specification>    <Summary>    <optional default setting>
    
    <Description> 

These user-specified options are added to the application framework options (defined dependent on whatever core/features/extensions are installed).
Also, the user may over ride default settings and descriptions on any application framework options by re-defining them in the script.

The parts of the specification are defined below.

=head4 name

The name defines the option name to be used at the command line, along with any command line option aliases (e.g. -log or -l, -logfile etc). Using the 
option in the script is via a HASH where the key is the 'main' option name.

Where an option has one or more aliases, this list of names is separated by '|'. By default, the first name defined is the 'main' option name used
as the option HASH key. This may be overridden by quoting the name that is required to be the main name.

For example, the following name definitions:

    -log|logfile|l
    -l|'log'|logfile
    -log

Are all access by the key 'log'

=head4 specification

(Note: This is a subset of the specification supported by L<Getopt::Long>).

The specification is optional. If not defined, then the option is a boolean value - is the user specifies the option on the command line
then the option value is set to 1; otherwise the option value is set to 0.

When the specification is defined, it is in the format:

   [ <flag> ] <type> [ <desttype> ]

The option requires an argument of the given type. Supported types
are:

=over 4

=item s

String. An arbitrary sequence of characters. It is valid for the
argument to start with C<-> or C<-->.

=item i

Integer. An optional leading plus or minus sign, followed by a
sequence of digits.

=item o

Extended integer, Perl style. This can be either an optional leading
plus or minus sign, followed by a sequence of digits, or an octal
string (a zero, optionally followed by '0', '1', .. '7'), or a
hexadecimal string (C<0x> followed by '0' .. '9', 'a' .. 'f', case
insensitive), or a binary string (C<0b> followed by a series of '0'
and '1').

=item f

Real number. For example C<3.14>, C<-6.23E24> and so on.

=back

The I<desttype> can be C<@> or C<%> to specify that the option is
list or a hash valued. This is only needed when the destination for
the option value is not otherwise specified. It should be omitted when
not needed.

The I<flag>, if used, can be C<dev:> to specify that the option is meant for application developer
use only. In this case, the option will not be shown in the normal help and man pages, but will
only be shown when the -man-dev option is used.

=head4 summary

The summary is a simple line of text used to summarise the option. It is used in the man pages in 'usage' mode.

=head3 default

Defaults values are optional. If they are defined, they are in the format:

    [default=<value>]

When a default is defined, if the user does not specify a value for an option then that option takes on the defualt value.

=head4 description

The summary is multiple lines of text used to fully describe the option. It is used in the man pages in 'man' mode.

=head3 Variable Expansion

Option values and default values can contain variables, defined using the standard Perl format:

	$<name>
	${<name>}

When the option is used, the variable is expanded and replaced with a suitable value. The value will be looked up from a variety of possible sources:
object fields (where the variable name matches the field name) or environment variables.

The variable name is looked up in the following order, the first value found with a matching name is used:

=over 4

=item *

Option names - the values of any other options may be used as variables in options

=item *

Application fields - any fields of the $app object may be used as variables

=item *

Environment variables - if no application fields match the variable name, then the environment variables are used

=back 

=head3 Script Usage

The application framework passes a reference to the options HASH as the second parameter to the application subroutine B<app>. Alternatively,
the script can call the app object's alias to the options accessor, i.e. the B<options> method which returns the options hash. Yet another
alternative is to call the options accessor method directly. These alternatives are shown below:


    sub app
    {
        my ($app, $opts_href, $args_href) = @_ ;
        
        # use parameter
        my $log = $opts_href->{log}
        
        # access alias
        my %options = $app->options() ;
        $log = $options{log} ;
        
        # access alias
        %options = $app->Options() ;
        $log = $options{log} ;
        
        # feature object
        %options = $app->feature('Options')->options() ;
        $log = $options{log} ;
    }



=head3 Examples

With the following script definition:

    [OPTIONS]
    
    -n|'name'=s        Test name [default=a name]
    
    String option, accessed as $opts_href->{name}. 
    
    -nomacro    Do not create test macro calls
    
    Boolean option, accessed as $opts_href->{nomacro}
    
    -log=s        Override default [default=another default]
    
    Over rides the default log option (specified by the framework)
    
    -int=i        An integer
    
    Example of integer option
    
    -float=f    An float
    
    Example of float option
    
    -array=s@    An array
    
    Example of an array option
    
    -hash=s%    A hash
    
    Example of a hash option

The following command line options are valid:

    -int 1234 -float 1.23 -array a -array b -array c -hash key1=val1 -hash key2=val2 -nomacro

Giving the options HASH values:

    'name' => 'a name'
    'nomacro' => 1
    'log' => 'another default'
    'int' => 1234
    'float' => 1.23
    'array' => [ 'a', 'b', 'c' ]
    'hash' => {
    	'key1' => 'val1',
    	'key2' => 'val2',
    }


=head2 Data

After the settings (described above), one or more extra data areas can be created by starting that area with a new __DATA__ line.

The __DATA__ section at the end of the script is used by the application framework to allow the script developer to define
various settings for his/her script. This setup is split into "headed" sections of the form:

  [ <section name> ]
  
  <settings>

In general, the <section name> is the name of a field value in the application, and <settings> is some text that the field will be set to. Sections
of this type are:

=over 4

=item B<[SUMMARY]> - Application summary text

A single line summary of the application. Used for man pages and usage summary. 

(Stored in the application's I<summary> field).

=item B<[DESCRIPTION]> - Application description text

Multiple line description of the application. Used for man pages. 

(Stored in the application's I<description> field).

=item B<[SYNOPSIS]> - Application synopsis [I<optional>]

Multiple line synopsis of the application usage. By default the application framework creates this if it is not specified. 

(Stored in the application's I<synopsis> field).

=item B<[NAME]> - Application name [I<optional>]

Name of the application usage. By default the application framework creates this if it is not specified. 

(Stored in the application's I<name> field).

=back

__DATA__ sections that have special meaning are:

=over 4

=item B<[OPTIONS]> - Application command line options

These are fully described in L<App::Framework::Features::Options>.

If no options are specified, then only those created by the application framework will be defined. 

=item B<[ARGS]> - Application command line arguments [I<optional>]

These are fully described in L<App::Framework::Features::Args>.

=back


=head3 Named Data

After the settings (described above), one or more extra data areas can be created by starting that area with a new __DATA__ line.

Each defined data area is named 'data1', 'data2' and so on. These data areas are user-defined multi line text that can be accessed 
by the object's accessor method L</data>, for example:

	my $data = $app->data('data1') ;

Alternatively, the user-defined data section can be arbitrarily named by appending a text name after __DATA__. For example, the definition:

	__DATA__
	
	[DESCRIPTION]
	An example
	
	__DATA__ test.txt
	
	some text
	
	__DATA__ a_bit_of_sql.sql
	
	DROP TABLE IF EXISTS `listings2`;
	 

leads to the use of the defined data areas as:

	my $file = $app->data('text.txt') ;
	# or
	$file = $app->data('data1') ;

	my $sql = $app->data('a_bit_of_sql.sql') ;
	# or
	$file = $app->Data('data2') ;


=head3 Variable Expansion

The data text can contain variables, defined using the standard Perl format:

	$<name>
	${<name>}

When the data is used, the variable is expanded and replaced with a suitable value. The value will be looked up from a variety of possible sources:
object fields (where the variable name matches the field name) or environment variables.

The variable name is looked up in the following order, the first value found with a matching name is used:

=over 4

=item *

Option names - the values of any command line options may be used as variables

=item *

Arguments names - the values of any command line arguments may be used as variables

=item *

Application fields - any fields of the $app object may be used as variables

=item *

Environment variables - if no application fields match the variable name, then the environment variables are used

=back 

=head3 Data Comments

Any lines starting with:

    __#

are treated as comment lines and not included in the data.




=head2 Directories

The framework sets up various directory paths automatically, as described below.

=head3 @INC path

App::Framework automatically pushes some extra directories at the start of the Perl include library path. This allows you to 'use' application-specific
modules without having to install them globally on a system. The path of the executing Perl application is found by following any links until
an actually Perl file is found. The @INC array has the following added:

	* $progpath
	* $progpath/lib
	
i.e. The directory that the script resides in, and a sub-directory 'lib' will be searched for application-specific modules.

Note that this is the path also used when the framework loads in the core personality, and any optional extensions.

	

=head2 EMBEDDING

A script may be developed and debugged using the App::Framework::Lite module installed on a system, and then turned into a standalone Perl
script by embedding the App::Framework::Lite module into the script file. Also, a developer may choose to also embed any user library modules
related to this script (or may just deliver them in their dubdirectory along with the standalone script).

=head3 Embedding Procedure

When a script is using the App::Framework::Lite module, some developer command line options are automatically added to the script. The developer
uses these options in the embedding process:

=over 4

=item -alf-embed

Causes the script to create a standalone version of itself

=item -alf-embed-lib

By default, the script also embeds any user library modules (i.e. any 'use'd modules that are located under $progpath/ or $progpath/lib/).

Specifying this option set to 0 prevents these modules from being embedded.

=item -alf-compress

By default the embedded modules are stored in a compressed format (whitespace and comments removed).

Specifying this option set to 0 prevents these modules from being compressed. If you have any problems with the embedded modules not working, then try setting
this option to 0 and check the resulting script.

=back 

=head3 Examples

If you have a script test.pl that uses App::Framework::Lite and a user module MyLib.pm (stored in the same directory as test.pl), then you
would create a new, stand-alone script alf-test.pl by running any of the following:

=head4 Embded compressed App::Framework::Lite and user modules

	perl test.pl -alf-embed alf-test.pl

Results in alf-test.pl having the App::Framework::Lite module and MyLib.pm embedded in a compressed version. The script is then completely stand-alone.

=head4 Embded compressed App::Framework::Lite

	perl test.pl -alf-embed alf-test.pl -alf-embed-lib 0

Results in alf-test.pl having the App::Framework::Lite module embedded in a compressed version, but the user module MyLib.pm would need to be
delivered along with the script for it to work.

=head4 Embded readable App::Framework::Lite and user modules

	perl test.pl -alf-embed alf-test.pl -alf-compress 0

Results in alf-test.pl having the App::Framework::Lite module and MyLib.pm embedded in a readable version. The script is completely stand-alone,
but much larger than if the modules had been compressed. This is useful for debugging module problems (especially with a debugger!).

=head2 FIELDS

The following fields should be defined either in the call to 'new()' or as part of the application configuration in the __DATA__ section:

 * name = Program name (default is name of program)
 * summary = Program summary text
 * synopsis = Synopsis text (default is program name and usage)
 * description = Program description text
 * history = Release history information
 * version = Program version (default is value of 'our $VERSION')

 * app_start_fn = Function called before app() function (default is application-defined 'app_start' subroutine if available)
 * app_fn = Function called to execute program (default is application-defined 'app' subroutine if available)
 * app_end_fn = Function called after app() function (default is application-defined 'app_end' subroutine if available)
 * usage_fn = Function called to display usage information (default is application-defined 'usage' subroutine if available)

During program execution, the following values can be accessed:

 * package = Name of the application package (usually main::)
 * filename = Full filename path to the application (after following any links)
 * progname = Name of the program (without path or extension)
 * progpath = Pathname to program
 * progext = Extension of program

=cut

use 5.008004;

use strict ;


our $VERSION = "1.09" ;


#============================================================================================
# USES
#============================================================================================
use Carp ;
use Cwd ;
use Getopt::Long qw(:config no_ignore_case) ;
use Pod::Usage ;
use File::Basename ;
use File::Path ;
use File::Temp ;
use File::Spec ;
use File::DosGlob 'glob' ;
#use File::Which ;


#============================================================================================
# OBJECT HIERARCHY
#============================================================================================
our @ISA ; 

#============================================================================================
# GLOBALS
#============================================================================================

my $class_debug ;

# default to state that the module is embedded (overwritten inside BEGIN block)
my $EMBEDDED = 0 ;

# Maximum line length when embedding (e.g. ensures Clearcase doesn't think file is binary!)
my $MAX_LINE_LEN = 5000 ;

# Keep track of import info
my $import_args ;

# Run error action
our $ON_ERROR_DEFAULT = 'fatal' ;

## Set up variables
my	%FIELDS = (
		'name'				=> undef,
		'progname'			=> undef,
		'progpath'			=> undef,
		'progext'			=> undef,
		'package'			=> undef,
		'filename'			=> undef,
		'version'			=> undef,
		'app'				=> undef,

		'synopsis'			=> "",
		'description'		=> "",
		'summary'			=> "",
		
		'debug'				=> 0,
		
		'app_start_fn'	=> undef,	
		'app_fn'		=> undef,	
		'app_end_fn'	=> undef,
	
		## Data fields
		'_data'				=> [],
		'_data_hash'		=> {},
		
		## Options fields
		'_user_options'		=> [],
		'_options_list'		=> [],
		'_options'			=> {},
		'_get_options'		=> [],
		'_option_fields_hash'		=> {},
		'option_names'		=> [],
		'opts_feature_args'	=> '',
		
		## Args fields
		'user_args'			=> [],		# User-specified args
		'argv'				=> [],		# ref to @ARGV
		'arg_names'			=> [],		# List of arg names
		'_arg_list'			=> [],	# Final ARRAY ref of args - EXCLUDING any opened files
		'_args'				=> {},	# Final args HASH - key = arg name; value = arg value
		'_arg_names_hash'	=> {},	# List of HASHes, each hash contains details of an arg
		'_fh_list'			=> [],	# List of any opened file handles
		'args_feature_args'	=> '',
		
		## Exit
		'exit_type'			=> 'exit',

		## Run fields
		'cmd'		=> undef,
		'args'		=> undef,
		'timeout'	=> undef,
		'nice'		=> undef,
		'dryrun'	=> 0,
		
		'on_error'	=> $ON_ERROR_DEFAULT,
		'error_str'	=> "",
		'required'	=> {},
		
		'check_results'	=> undef,
		'progress'		=> undef,
		
		'status'	=> 0,
		'results'	=> [],
		
		'norun'		=> 0,


		'log'		=> {
			'all'		=> 0,
			'cmd'		=> 0,
			'results'	=> 0,
			'status'	=> 0,
		},

		## Logging
		'logfile'		=> undef,
		'mode'			=> 'truncate',
		'to_stdout'		=> 0,
		
		'_started'		=> 0,
		
	) ;

my $POD_HEAD =	"=head" ;
my $POD_OVER =	"=over" ;

my @DEFAULT_OPTS = (
	['debug=i',			'Set debug level', 	'Set the debug level value', ],
	['v|"verbose"',		'Verbose output',	'Make script output more verbose', ],
	['dryrun|"norun"',	'Dry run', 			'Do not execute anything that would alter the file system, just show the commands that would have executed'],
	['h|"help"',		'Print help', 		'Show brief help message then exit'],
	['man',				'Full documentation', 'Show full man page then exit' ],
	['man-dev',			'Full developer\'s documentation', 'Show full man page for the application developer then exit' ],
	['log=s',			'Log file', 		'Specify a log file', ],
	['dev:pod',			'Output full pod', 	'Show full man page as pod then exit' ],
	['dev:dbg-data',		'Debug option: Show __DATA__', 				'Show __DATA__ definition in script then exit' ],
	['dev:dbg-data-array',	'Debug option: Show all __DATA__ items', 	'Show all processed __DATA__ items then exit' ],
	['dev:alf-info',	'Module information', 	'Display information about the App::Framework::Lite module then exit' ],
	['dev:alf-debug=i',	 'Debug App::Framework::Lite', 	'Set the debug level value of the App::Framework::Lite module', ],
#@NO-EMBED BEGIN
	['dev:alf-embed=s',		'Embed module', 	'Embed the App::Framework::Lite module into script then exit. Specify the filename of the new script.' ],
	['dev:alf-embed-lib=i',	'Embed libraries', 	'(Only used when embedding). Embed user modules as well as the App::Framework::Lite module.', 1 ],
	['dev:alf-compress=i',	'Compress embedded', 	'(Only used when embedding). Compress the embedded modules.', 1 ],
#@NO-EMBED END
	) ;

our @USED = (
	'Carp',
	'Cwd',
	'Getopt::Long qw(:config no_ignore_case)',
	'Pod::Usage',
	'File::Basename',
	'File::Path',
	'File::Temp',
	'File::Spec',
	'File::DosGlob qw(glob)',
) ;

our @OPT_MOD = (
	'File::Which',
) ;
our %AVAILABLE_MOD ;


#============================================================================================
BEGIN {

#@NO-EMBED BEGIN
	# Clear flag for non-embedded
	$EMBEDDED = 1 ;
#@NO-EMBED END

	## Get caller information
	my ($package, $filename, $line, $subr, $has_args, $wantarray) = caller(0) ;

	## Add a couple of useful function calls into the caller namespace
	{
		no warnings 'redefine';
		no strict 'refs';

		foreach my $fn (qw/go/)	
		{
			*{"${package}::$fn"} = sub {  
			    my @callinfo = caller(0);
				my $app = App::Framework::Lite->new(@_,
					'_caller_info' => \@callinfo) ;
				$app->$fn() ;
			};
		}	
	}
	
	## Optional modules
	foreach my $mod (@OPT_MOD)
	{
		# see if we can load up the package
		if (eval "require $mod") 
		{
			$mod->import() ;
			++$AVAILABLE_MOD{$mod} ;

		}
	}
}

#============================================================================================
# Set up module import
sub import 
{
    my $pkg     = shift;

	# save for later    
    $import_args = join ' ', @_ ;

	## Get caller information
	my ($package, $filename, $line, $subr, $has_args, $wantarray) = caller(0) ;

	## Set program info
	App::Framework::Lite->_set_paths($filename) ;
	

	## Import modules into caller space
	my $include = "package $package;\n" ;
	foreach my $use (@USED)
	{
		$include .= "use $use ;\n" ;
	}
	foreach my $use (keys %AVAILABLE_MOD)
	{
		if ($AVAILABLE_MOD{$use})
		{
			$include .= "use $use ;\n" ;
		}
	}
	eval $include ;
	die "Error: Unable to load modules into $package : $@" if $@ ;
}


#============================================================================================

=head2 METHODS

=over 4

=cut


#----------------------------------------------------------------------------------------------

=item B< new([%args]) >

Create a new object.

The %args passed down to the parent objects.


=cut


sub new
{
	my ($obj, %args) = @_ ;

	my $class = ref($obj) || $obj ;

	# Create object
	my $this = {} ;
	bless ($this, $class) ;
	$this->{'app'} = $this ;

	## get import args
	if (exists($args{'specification'}))
	{
		$import_args = delete $args{'specification'} ;
	}
	

	## init
	foreach my $field (keys %FIELDS)
	{
		$this->{$field} = $FIELDS{$field} ;
	}
	$this->_setup_modules() ;
	
	## Get caller information
	my $callinfo_aref = delete $args{'_caller_info'} ;
	if (!$callinfo_aref)
	{
		$callinfo_aref = [ caller(0) ] ;	
	}
	my ($package, $filename, $line, $subr, $has_args, $wantarray) = @$callinfo_aref ;
	$this->set(
		'package'	=> $package,
		'filename'	=> $filename,
	) ;
	
	## Set program info
	$this->_set_paths($filename) ;
	
	## set up functions
	foreach my $fn_aref (
		# prefered
		['app_start',	'app_start'],
		['app',			'app'],
		['app_end',		'app_end'],
		['usage',		'usage'],

		# alternates
		['app_begin',	'app_start'],
		['app_enter',	'app_start'],
		['app_init',	'app_start'],
		['app_finish',	'app_end'],
		['app_exit',	'app_end'],
		['app_term',	'app_end'],
	)
	{
		my ($fn, $alias) = @$fn_aref ;
		
		# Only add function if it's not already been specified
		$this->_register_fn($fn, $alias) ;
	}


	## Get version
	$this->_register_scalar('VERSION', 'version') ;

	## Ensure name set
	if (!$this->{name})
	{
		$this->{name} = $this->{progname} ;		
	}
	
	# Process import args
	#
	my %feature_args ;

	my $personality ;
	my @features ;
	my @extensions ;
	my %extension_args ;
	
	# Expect something of the form:
	# :Personality ::Extension ::Ext(option1 option2) +Feature +Feat(opt1, opt2)
	#
	#                           type        name       args 
	while ($import_args =~ /\s*([\:\+]{1,2})([\w_]+)\s*(?:\(([^\)]+)\)){0,1}/g)
	{
		my ($type, $name, $args) = ($1, $2, $3) ;
		if ($type eq ':')
		{
			if ($personality)
			{
				croak "Sorry, App::Framework::Lite does not support multiple personalities (please see a psychiatrist!)" ;
			}
			if ($args)
			{
				warn "Sorry, personalities do not support arguments" ;
			}
			$personality = $name ;
		}
		elsif ($type eq '::')
		{
			push @extensions, $name ;
			$extension_args{$name} = $args || "" ;
		}
		elsif ($type eq '+')
		{
			push @features, $name ;
			$feature_args{$name} = $args || "" ;
		}
		else
		{
			croak "App::Framework does not understand the import string \"$import_args\" at \"$type\" " ;
		}
	}

	# set feature args
	foreach my $feature (keys %feature_args)
	{
		my $field = lc $feature ;
		$field .= "_feature_args" ;
		$this->{$field} = $feature_args{$feature} ;
	}
	
	## Set any fields
	$this->set(%args) ;
	
	return($this) ;
}

#----------------------------------------------------------------------------

=item B<set(%args)>

Set one or more settable parameter.

=cut

sub set
{
	my $this = shift ;
	my (%args) = @_ ;

	foreach my $field (keys %FIELDS)
	{
		if (exists($args{$field})) 
		{
			$this->{$field} = $args{$field}  ;
		}
	}
}

#----------------------------------------------------------------------------

=item B<vars()>

Return the current object variables

=cut

sub vars
{
	my $this = shift ;
	my %vars = () ;

	foreach my $field (keys %FIELDS)
	{
		if (!ref($this->{$field}) || (ref($this->{$field}) eq 'SCALAR'))
		{
			$vars{$field} = $this->{$field} ;
		}
	}
	
	return %vars ;
}

#----------------------------------------------------------------------------

=item B<feature($name [, %args])>

Dummy for compatibility with App::Framework

=cut

sub feature
{
	my $this = shift ;
	my ($name, %args) = @_ ;

	return $this ;	
}




#----------------------------------------------------------------------------

=item B<go()>

Execute the application.

Calls the following methods in turn:

	* app_start
	* application
	* app_end
	* exit
 
=cut


sub go
{
	my $this = shift ;

	$this->app_start() ;
	$this->app_handle_opts() ;
	$this->application() ;
	$this->app_end() ;

	$this->exit(0) ;
}


#----------------------------------------------------------------------------

=item B<getopts()>

Convert the (already processed) options list into settings. 

Returns result of calling GetOptions

=cut

sub getopts
{
	my $this = shift ;

	# get options	
	my $ok = $this->get_options() ;

	# If ok, get any specified filenames
	if ($ok)
	{
		# Get args
		my $arglist = $this->get_args() ;

		$this->_dbg_prt(["getopts() : arglist=", $arglist], 2) ;
	}
	
	## Expand vars
	my %values ;
	my ($opt_values_href, $opt_defaults_href) = $this->option_values_hash() ;
	my ($args_values_href) = $this->args_values_hash() ;
	
	%values = (%$opt_values_href) ;
	my %args_clash ;
	foreach my $key (keys %$args_values_href)
	{
		if (exists($values{$key}))
		{
			$args_clash{$key} = $args_values_href->{$key} ;
		}
		else
		{
			$values{$key} = $args_values_href->{$key} ;
		}
	}

	my @vars ;
	my %app_vars = $this->vars ;
	push @vars, \%app_vars ;
	push @vars, \%ENV ;

	## expand all vars
	$this->expand_keys(\%values, \@vars) ;
	
	# set new values
	foreach my $key (keys %$opt_values_href)
	{
		$opt_values_href->{$key} = $values{$key} ;
	}
	foreach my $key (keys %$args_values_href)
	{
		$args_values_href->{$key} = $values{$key} ;
	}

	## handle any name clash
	if (keys %args_clash)
	{
		unshift @vars, \%values ;
		$this->expand_keys(\%args_clash, \@vars) ;

		# set new values
		foreach my $key (keys %args_clash)
		{
			$args_values_href->{$key} = $args_clash{$key} ;
		}
	}

	## update settings
	$this->option_values_set($opt_values_href, $opt_defaults_href) ;
	$this->args_values_set($args_values_href) ;

	return $ok ;
}

#----------------------------------------------------------------------------

=item B<app_start()>

Set up before running the application.

Calls the following methods in turn:

* getopts
* [internal _expand_vars method]
* options
 
=cut


sub app_start
{
	my $this = shift ;

	## Process data
	$this->process_data() ;

	## Get options
	
	# get the list suitable for GetOpts
	my $get_options_aref = $this->{_get_options} ;

	## Get options
	# NOTE: Need to do this here so that derived objects work properly
	my $ok = $this->getopts() ;
	
	## Expand any variables in the application object field values
	$this->_expand_vars() ;

	# Handle options errors here after expanding variables
	unless ($ok)
	{
		$this->usage('opt') ;
		$this->exit(1) ;
	} 

	## Run application function
	my %options = $this->options() ;
	$this->_exec_fn('app_start', $this, \%options) ;


	## expand data variables
	my %app_vars = $this->vars() ;
	my %opts = $this->options() ;
	my $args_values_href = $this->args_values_hash() ;
	my $data_href = $this->{_data_hash} ;
	$this->expand_keys($data_href, [\%opts, $args_values_href, \%app_vars, \%ENV]) ;
}

#----------------------------------------------------------------------------

=item B<app_handle_opts()>

Handles the default options (for example -man, -help etc)
 

=cut


sub app_handle_opts
{
	my $this = shift ;

	## Get options
	my %options = $this->options() ;

	## Handle special options
	my %opts = $this->options() ;
	if ($opts{'man'} || $opts{'help'})
	{
		my $type = $opts{'man'} ? 'man' : 'help' ;
		$this->usage($type) ;
		$this->exit(0) ;
	}
	if ($opts{'man-dev'})
	{
		$this->usage('man-dev') ;
		$this->exit(0) ;
	}
	if ($opts{'pod'})
	{
		print $this->pod() ;
		$this->exit(0) ;
	}
	if ($opts{'alf-debug'})
	{
		$this->{debug} = $opts{'alf-debug'} ;
	}
	if ($opts{'dbg-data'})
	{
		$this->_show_data() ;
		$this->exit(0) ;
	}
	if ($opts{'dbg-data-array'})
	{
		$this->_show_data_array() ;
		$this->exit(0) ;
	}

	if ($opts{'alf-info'})
	{
		print "App::Framework::Lite info\n" ;
		print "  Version:  $VERSION\n" ;
		print "  Embedded: " . ($EMBEDDED ? "yes" : "no") . "\n" ;
		$this->exit(0) ;
	}

#@NO-EMBED BEGIN
	if ($opts{'alf-embed'})
	{
		my $src = $this->{'filename'} ;
#		my $dest = $this->{'progpath'} . '/' . "alf-" . $this->{'progname'} . $this->{'progext'} ;
		my $dest = $opts{'alf-embed'} ;
		my %libs = $this->embed($src, $dest, $opts{'alf-compress'}, $opts{'alf-embed-lib'}) ;
		print "Embedded App::Framework::Lite into $src. Stand-alone script saved as $dest.\n" ;
		print "Embedded the following library modules:\n" ;
		foreach my $mod (sort {$libs{$a}{'order'} <=> $libs{$b}{'order'} } keys %libs)
		{
			print "    $mod\n" ;
		}
		
		print "Have a nice life.\n" ;
		$this->exit(0) ;
	}
#@NO-EMBED END

	if ($opts{'log'})
	{
		$this->{logfile} = $opts{'log'} ;
	}

}


#----------------------------------------------------------------------------

=item B<application()>

Execute the application.
 
Calls the following methods in turn:

* (Application registered 'app' function)
 

=cut

sub application
{
	my $this = shift ;

	## Get options
	my %options = $this->options() ;

	## Check args here (do this AFTER allowing derived objects/features a chance to check the options etc)
	$this->check_args() ;
	
	# get args
	my %args = $this->arg_hash() ;

	## Run application function
	$this->_exec_fn('app', $this, \%options, \%args) ;

	## Close any open arguments
	$this->close_args() ;
}

#----------------------------------------------------------------------------

=item B<app_end()>

Tidy up after the application.

Calls the following methods in turn:

* (Application registered 'app_end' function)
 

=cut


sub app_end
{
	my $this = shift ;

	# get options
	my %options = $this->options() ;

	## Execute function
	$this->_exec_fn('app_end', $this, \%options) ;
}



#----------------------------------------------------------------------------

=item B<exit()>

Exit the application.
 
=cut


sub exit
{
	my $this = shift ;
	my ($exit_code) = @_ ;

	if ($this->{'exit_type'} =~ /exit/i)
	{
		exit $exit_code ;
	}
	else
	{
		# check for eval (for testing)
		if ($^S) 
		{
			die "End of application. Exit code = $exit_code" ;
   		} 
   		else 
   		{
      		carp(@_);
			exit $exit_code ;
   		}
	}	
}


#----------------------------------------------------------------------------

=item B<usage($level)>

Show usage.

$level is a string containg the level of usage to display

	'opt' is equivalent to pod2usage(2)

	'help' is equivalent to pod2usage(1)

	'man' is equivalent to pod2usage(-verbose => 2)

=cut

sub usage
{
	my $this = shift ;
	my ($level) = @_ ;

	$level ||= "" ;

	# TODO: Work out a better way to convert pod without the use of external file!
	
	# get temp file
	my $fh = new File::Temp();
	my $fname = $fh->filename;
	
	# write pod
	my $developer = $level eq 'man-dev' ? 1 : 0 ;
	print $fh $this->pod($developer) ;
	close $fh ;

	# pod2usage 
	my ($exitval, $verbose) = (0, 0) ;
	($exitval, $verbose) = (2, 0) if ($level eq 'opt') ;
	($exitval, $verbose) = (1, 0) if ($level eq 'help') ;
	($exitval, $verbose) = (0, 2) if ($level =~ /^man/) ;

	# make file readable by all - in case we're running as root
	chmod 0644, $fname ;

#	system("perldoc",  $fname) ;
	pod2usage(
		-verbose	=> $verbose,
#		-exitval	=> $exitval,
		-exitval	=> 'noexit',
		-input		=> $fname,
		-noperldoc =>1,
		
		-title => $this->{name},
		-section => 1,
	) ;

	# remove temp file
	unlink $fname ;

}


#============================================================================================
# OPTIONS
#============================================================================================


#----------------------------------------------------------------------------

=item B< options() >

Returns the hash of options/values

=cut

sub options
{
	my $this = shift ;

$this->_dbg_prt( ["Options()\n"] ) ;

	my $options_href = $this->{_options} ;
	return %$options_href ;
}

#----------------------------------------------------------------------------

=item B< Options([%args]) >

Alias to L</options>

=cut

*Options = \&options ;


#----------------------------------------------------------------------------
#
#=item B<_expand_options()>
#
#Expand any variables in the options
#
#=cut
#
sub _expand_options 
{
	my $this = shift ;

$this->_dbg_prt(["_expand_options()\n"]) ;

	my $options_href = $this->{_options} ;
	my $options_fields_href = $this->{_option_fields_hash} ;

	# get defaults & options
	my (%defaults, %values) ;
	foreach my $opt (keys %$options_fields_href)
	{
		$defaults{$opt} = $options_fields_href->{$opt}{'default'} ;
		$values{$opt} = $options_href->{$opt} if defined($options_href->{$opt}) ;
	}
$this->_dbg_prt(["_expand_options: defaults=",\%defaults," values=",\%values,"\n"]) ;

#	# get replacement vars
#	my @vars ;
#	my $app = $this->app ;
#	if ($app)
#	{
#		my %app_vars = $app->vars ;
#		push @vars, \%app_vars ;
#	}
	
#	## expand
#	my @vars ;
#	push @vars, \%ENV ;
#	$this->expand_keys(\%values, \@vars) ;
#	push @vars, \%values ;	# allow defaults to use user-specified values
#	$this->expand_keys(\%defaults, \@vars) ;
#
#$this->_dbg_prt(["_expand_options - end: defaults=",\%defaults," values=",\%values,"\n"]) ;
	
	## Update
	foreach my $opt (keys %$options_fields_href)
	{
		# update defaults to reflect any user specified options
		$defaults{$opt} = $values{$opt} ;
		$options_fields_href->{$opt}{'default'} = $defaults{$opt} ;
		
		# update values
		$options_href->{$opt} = $values{$opt} if defined($options_href->{$opt}) ;
	}
}

#----------------------------------------------------------------------------

=item B<get_options()>

Use Getopt::Long to process the command line options. Returns 1 on success; 0 otherwise

=cut

sub get_options
{
	my $this = shift ;

	# Do final processing of the options
	$this->update() ;
	
	# get the list suitable for GetOpts
	my $get_options_aref = $this->{_get_options} ;

$this->_dbg_prt( ["get_options() : ARGV=", \@ARGV, " Options=", $get_options_aref], 2 ) ;

	# Parse options using GetOpts
	my $ok = GetOptions(@$get_options_aref) ;

	# Expand the options variables
	$this->_expand_options() ;

$this->_dbg_prt( ["get_options() : ok=$ok  Options now=", $get_options_aref], 2 ) ;

	return $ok ;
}


#----------------------------------------------------------------------------

=item B<option_entry($option_name)>

Returns the HASH ref of option if name is found; undef otherwise.

The HASH ref contains:

	'field' => option 'main' name 
	'spec' => specification string
	'summary' => summary text 
	'description' => description text
	'default' => default value (if specified)
	'pod_spec' => specification string suitable for pod output
	'type' => option type (e.g. s, f etc)
	'dest_type' => destination type (e.g. @, %)
	'developer' => developer only option (flag set if option is to be used for developer use only)
	'entry' => reference to the ARRAY that defined the option (as per L</append_options>) 

=cut

sub option_entry
{
	my $this = shift ;
	my ($option_name) = @_ ;

	my $option_fields_href = $this->{_option_fields_hash} ;
	my $opt_href ;
	if (exists($option_fields_href->{$option_name}))
	{
		$opt_href = $option_fields_href->{$option_name} ;
	}
	return $opt_href ;
}


#----------------------------------------------------------------------------

=item B<option_values_hash()>

Returns the options values and defaults HASH references in an array, values HASH ref
as the first element.

=cut

sub option_values_hash
{
	my $this = shift ;

	my $options_href = $this->{_options} ;
	my $options_fields_href = $this->{_option_fields_hash} ;

	# get defaults & options
	my (%values, %defaults) ;
	foreach my $opt (keys %$options_fields_href)
	{
		$defaults{$opt} = $options_fields_href->{$opt}{'default'} ;
		$values{$opt} = $options_href->{$opt} if defined($options_href->{$opt}) ;
	}

	return (\%values, \%defaults) ;
}

#----------------------------------------------------------------------------

=item B<option_values_set($values_href, $defaults_href)>

Sets the options values and defaults based on the HASH references passed in.

=cut

sub option_values_set
{
	my $this = shift ;
	my ($values_href, $defaults_href) = @_ ;

	my $options_href = $this->{_options} ;
	my $options_fields_href = $this->{_option_fields_hash} ;

	## Update
	foreach my $opt (keys %$options_fields_href)
	{
		# update defaults to reflect any user specified options
		$defaults_href->{$opt} = $values_href->{$opt} ;
		$options_fields_href->{$opt}{'default'} = $defaults_href->{$opt} ;
		
		# update values
		$options_href->{$opt} = $values_href->{$opt} if defined($options_href->{$opt}) ;
	}
}



#============================================================================================
# ARGS
#============================================================================================

#----------------------------------------------------------------------------

=item B< args([$name]) >

When called with no arguments, returns the full arguments list (same as call to method L</arg_list>).

When a name (or list of names) is specified: if the named arguments hash is available, returns the 
argument values as a list; otherwise just returns the complete args list.

=cut

sub args
{
	my $this = shift ;
	my (@names) = @_ ;
	
	my $args_href = $this->{_args} ;
	my @args = $this->arg_list() ;

	if (keys %$args_href)
	{
		# do named args
		if (@names)
		{
			@args = () ;
			foreach my $name (@names)
			{
				push @args, $args_href->{$name} if exists($args_href->{$name}) ;
			}			
		}
	}	
	
	return @args ;
}

#----------------------------------------------------------------------------

=item B< Args([$name]) >

Alias to L</args>

=cut

*Args = \&args ;


#----------------------------------------------------------------------------

=item B< arg_list() >

Returns the full arguments list. This is the list of arguments, as specified
at the command line by the user.

=cut

sub arg_list
{
	my $this = shift ;

	my $args_aref = $this->{_arg_list} ;

	return @$args_aref ;
}

#----------------------------------------------------------------------------

=item B< arg_hash() >

Returns the full arguments hash.

=cut

sub arg_hash
{
	my $this = shift ;

	my $args_href = $this->{_args} ;
	return %$args_href ;
}


#----------------------------------------------------------------------------

=item B<append_args($args_aref)>

Append the options listed in the ARRAY ref I<$args_aref> to the current args list

=cut

sub append_args
{
	my $this = shift ;
	my ($args_aref) = @_ ;

$this->_dbg_prt(["Args: append_args()\n"]) ;

	my @combined_args = (@{$this->{user_args}}, @$args_aref) ;
	$this->{user_args} = \@combined_args ;

$this->_dbg_prt(["Options: append_args() new=", $args_aref], 2)   ;
$this->_dbg_prt(["combined=", \@combined_args], 2)   ;

	## Build new set of args
	$this->update() ;
	
	return @combined_args ;
}

#----------------------------------------------------------------------------

=item B< update() >

Take the list of args (created by calls to L</append_args>) and process the list into the
final args list.

Each entry in the ARRAY is an ARRAY ref containing:

 [ <arg spec>, <arg summary>, <arg description>, <arg default> ]

Returns the hash of args/values

=cut

sub update
{
	my $this = shift ;

$this->_dbg_prt(["Args: update()\n"]) ;

	## get user settings
	my $args_aref = $this->{user_args} ;

	## set up internals
	
	# rebuild these
	my $args_href = {} ;

	# keep full details
	my $args_names_href = {} ;

	## fill args_href, get_args_aref
	my $args_list = [] ;
	
	# Cycle through
	my $optional = 0 ;
	my $last_dest_type ;
	foreach my $arg_entry_aref (@$args_aref)
	{
$this->_dbg_prt(["Arg entry=", $arg_entry_aref], 2)   ;

		my ($arg_spec, $summary, $description, $default_val) = @$arg_entry_aref ;
		
		## Process the arg spec
		my ($name, $pod_spec, $dest_type, $arg_type, $arg_direction, $arg_optional, $arg_append, $arg_mode) ;
		($name, $arg_spec, $pod_spec, $dest_type, $arg_type, $arg_direction, $arg_optional, $arg_append, $arg_mode) =
			$this->_process_arg_spec($arg_spec) ;

		if ($last_dest_type)
		{
			$this->throw_fatal("Application definition error: arg $name defined after $last_dest_type defined as array") ;
		}
		$last_dest_type = $name if $dest_type ;
		
		# Set default if required
		$args_href->{$name} = $default_val if (defined($default_val)) ;

		# See if optional
		$arg_optional++ if defined($default_val) ;
		if ($optional && !$arg_optional)
		{
			$this->throw_fatal("Application definition error: arg $name should be optional since previous arg is") ;
		}		
		$optional ||= $arg_optional ;

$this->_dbg_prt(["Args: update() - arg_optional=$arg_optional optional=$optional\n"]) ;
		
		# Create full entry
		my $href = $this->_new_arg_entry($name, $arg_spec, $summary, $description, $default_val, $pod_spec, $arg_type, $arg_direction, $dest_type, $optional, $arg_append, $arg_mode) ;
		$args_names_href->{$name} = $href ;

$this->_dbg_prt(["Arg $name HASH=", $href], 2)   ;

		# save arg in specified order
		push @$args_list, $name ; 
	}

$this->_dbg_prt(["update() - END\n"], 2) ;

	## Save
	$this->{arg_names} = $args_list ;
	$this->{_args} = $args_href ;
	$this->{_arg_names_hash} = $args_names_href ;

	return %$args_href ;
}



#-----------------------------------------------------------------------------

=item B< check_args() >

At start of application, check the arguments for valid files etc.

=cut

sub check_args 
{
	my $this = shift ;

	# specified args
	my $argv_aref = $this->{argv} ;
	# values
	my $args_href = $this->{_args} ;
	# details
	my $arg_names_href = $this->{_arg_names_hash} ;

	# File handles
	my $fh_aref = $this->{_fh_list} ;

$this->_dbg_prt(["check_args() Names=", $arg_names_href, "Values=", $args_href, "Name list=", $this->{arg_names}], 2)   ;
	
		
	## Check feature settings
	my ($open_out, $open_in) = (1, 1) ;
	my $feature_args = $this->{args_feature_args} ;
	if ($feature_args =~ m/open\s*=\s*(out|in|no)/i)
	{
		if ($1 =~ /out/i)
		{
			++$open_out ;
		}
		elsif ($1 =~ /in/i)
		{
			++$open_in ;
		}
		else
		{
			# none
			$open_in = 0;
			$open_out = 0;
		}
	}	
#	elsif ($feature_args =~ m/open/i)
#	{
#		## open both
#		++$open_out ;
#		++$open_in ;
#	}	
	
	## Process each arg checking that it's been specified (where required)
	my $idx = -1 ;
	my $arg_list = $this->{arg_names} ;
	foreach my $name (@$arg_list)
	{
#		# skip if optional
#		next if $arg_names_href->{$name}{'optional'} ;

		# create file handle name
		my $fh_name = "${name}_fh";		

		my $type = "" ;
		if ($arg_names_href->{$name}{'type'} eq 'f')
		{
			$type = "file " ;
		}
		if ($arg_names_href->{$name}{'type'} eq 'd')
		{
			$type = "directory " ;
		}

		my $value = $args_href->{$name} ;
		my @values = ($value) ;

		## Special handling for @* spec
		if ($arg_names_href->{$name}{'dest_type'})
		{
	$this->_dbg_prt([" + + special dest type\n"], 2) ;
			if (defined($value))
			{
				@values = @$value ;
			}
			
			push @values, '' unless @values ;

			if ($open_in && ($arg_names_href->{$name}{'type'} eq 'f'))
			{
				$args_href->{$fh_name} = [] ;
			}
		}

$this->_dbg_prt([" + values (@values) [".scalar(@values)."]\n"], 2) ;

		## Very special case of * spec with no args - set fh to STDIN if required
		if ($arg_names_href->{$name}{'dest_type'} eq '*')
		{
			if (!defined($value) || scalar(@$value)==0)
			{
				if ($open_in && ($arg_names_href->{$name}{'type'} eq 'f'))
				{
					# Create new entry
					my $href = $this->_new_arg_entry($fh_name) ;
					$arg_names_href->{$fh_name} = $href ;
					
					# set value
					$args_href->{$fh_name} = [\*STDIN] ;

					$args_href->{$name} ||= [] ;
					push @{$args_href->{$name}}, 'STDIN' ;
					
					next ;
				}
			}
		}
		
		
		## Check all of the values
		foreach my $val (@values)
		{
			
			++$idx ;
			my $arg_optional = $arg_names_href->{$name}{'optional'} ;
			
$this->_dbg_prt([" + checking $name value=$val, type=$type, optional=$arg_optional ..\n"], 2) ;
		
			# First check that an arg has been specified
			if ($idx >= scalar(@$argv_aref))
			{
				# Ignore if * type -OR- optional
				if ( ($arg_names_href->{$name}{'dest_type'} ne '*') && (! $arg_optional) )
				{
					$this->_complain_usage_exit("Must specify input $type\"$name\"") ;
				}
			}
			
			next unless $val ;
			
			## Input
			if ($arg_names_href->{$name}{'direction'} eq 'i')
			{
	$this->_dbg_prt([" + Check $val for existence\n"], 2) ;
				
				## skip checks if optional and no value specified (i.e. do the check if a default is specified)
				if (!$arg_optional && $val)
				{
					# File check
					if ( ($arg_names_href->{$name}{'type'} eq 'f') && (! -f $val) )
					{
						$this->_complain_usage_exit("Must specify a valid input filename for \"$name\"") ;
					}
					# Directory check
					if ( ($arg_names_href->{$name}{'type'} eq 'd') && (! -d $val) )
					{
						$this->_complain_usage_exit("Must specify a valid input directory for \"$name\"") ;
					}
				}
				else
				{
	$this->_dbg_prt([" + Skipped checks opt=$arg_optional val=$val bool=".."...\n"], 2) ;
					
				}	
				
				
				## File open
				if ($open_in && ($arg_names_href->{$name}{'type'} eq 'f'))
				{
					open my $fh, "<$val" ;
					if ($fh)
					{
						push @$fh_aref, $fh ;
						
						if ($arg_names_href->{$name}{'mode'} eq 'b')
						{
							binmode $fh ;
						}
	
						# Create new entry
						my $href = $this->_new_arg_entry($fh_name) ;
						$arg_names_href->{$fh_name} = $href ;
						
						# set value
						if ($arg_names_href->{$name}{'dest_type'})
						{
							$args_href->{$fh_name} ||= [] ;
							push @{$args_href->{$fh_name}}, $fh ;
						}
						else
						{
							$args_href->{$fh_name} = $fh ;
						}
					}
					else
					{
						$this->_complain_usage_exit("Unable to read file \"$val\" : $!") ;
					}
				}
			}
			
			## Output
			if ($open_out)
			{
				if (($arg_names_href->{$name}{'direction'} eq 'o') && ($arg_names_href->{$name}{'type'} eq 'f'))
				{
					my $mode = '>' ;	
					if ($arg_names_href->{$name}{'append'})
					{
						$mode .= '>' ;
					}
					
					open my $fh, "$mode$val" ;
					if ($fh)
					{
						push @$fh_aref, $fh ;
						
						if ($arg_names_href->{$name}{'mode'} eq 'b')
						{
							binmode $fh ;
						}
	
						# Create new entry
						my $href = $this->_new_arg_entry($fh_name) ;
						$arg_names_href->{$fh_name} = $href ;
						
						# set value
						$args_href->{$fh_name} = $fh ;
					}
					else
					{
						my $md = $arg_names_href->{$name}{'append'} ? 'append' : 'write' ;
		
						$this->_complain_usage_exit("Unable to $md file \"$val\" : $!") ;
					}
				}
			}
		}
	}
		
}

#-----------------------------------------------------------------------------

=item B< close_args() >

If any arguements cause files/devices to be opened, this shuts them down

=cut

sub close_args 
{
	my $this = shift ;

	# File handles
	my $fh_aref = $this->{_fh_list} ;
	
	foreach my $fh (@$fh_aref)
	{
		close $fh ;
	}

}



#----------------------------------------------------------------------------

=item B<get_args()>

Finish any args processing and return the arguments list

=cut

sub get_args
{
	my $this = shift ;

	# save @ARGV
	$this->{argv} = \@ARGV ;
	my @args = @ARGV ;

	# Copy values over
	$this->_process_argv() ;

	my %args ;
	
	%args = $this->arg_hash() ;
$this->_dbg_prt(["Args before expand : hash=", \%args]) ;

	# Expand the args variables
	$this->_expand_args() ;

	# Set arg list
	my @arg_array ;
	%args = $this->arg_hash() ;
	my $arg_list = $this->{arg_names} ;
	foreach my $name (@$arg_list)
	{
		push @arg_array, $args{$name} ;
	}
	$this->{_arg_list} = \@arg_array ;


	# return arglist
	return $this->arg_list ;
}

#----------------------------------------------------------------------------

=item B<arg_entry($arg_name)>

Returns the HASH ref of arg if name is found; undef otherwise

=cut

sub arg_entry
{
	my $this = shift ;
	my ($arg_name) = @_ ;

	my $arg_names_href = $this->{_arg_names_hash} ;
	my $arg_href ;
	if (exists($arg_names_href->{$arg_name}))
	{
		$arg_href = $arg_names_href->{$arg_name} ;
	}
	return $arg_href ;
}


#----------------------------------------------------------------------------

=item B<args_values_hash()>

Returns the args values HASH reference.

=cut

sub args_values_hash 
{
	my $this = shift ;

	my $args_href = $this->{_args} ;
	my $args_names_href = $this->{_arg_names_hash} ;

	# get args
	my %values ;
	foreach my $arg (keys %$args_names_href)
	{
		$values{$arg} = $args_href->{$arg} if defined($args_href->{$arg}) ;
	}

	return \%values ;
}

#----------------------------------------------------------------------------

=item B<args_values_set($values_href)>

Sets the args values based on the values in the HASH reference B<$values_href>.

=cut

sub args_values_set 
{
	my $this = shift ;
	my ($values_href) = @_ ;

	my $args_href = $this->{_args} ;
	my $args_names_href = $this->{_arg_names_hash} ;

	## Update
#	foreach my $arg (keys %$args_names_href)
#	{
#		$args_href->{$arg} = $values_href->{$arg} if defined($args_href->{$arg}) ;
#	}

	# Cycle through
	my $names_aref = $this->{arg_names} ;
	foreach my $arg (@$names_aref)
	{
		if ( defined($args_href->{$arg}) )
		{
			my $arg_entry_href = $this->arg_entry($arg) ;
			
			$args_href->{$arg} = $values_href->{$arg} ;
			$arg_entry_href->{'default'} = $values_href->{$arg} ;
		}
	}
}

#----------------------------------------------------------------------------
#
#=item B<_expand_vars()>
#
#Run through some of the application variables/fields and expand any instances of variables embedded
#within the values.
#
#Example:
#
#	__DATA_  
#
#	[SYNOPSIS]
#	
#	$name [options] <rrd file(s)>
#
#Here the 'synopsis' field contains the $name field variable. This needs to be expanded to the value of $name.
#
#NOTE: Currently this will NOT cope with cross references (so, if in the above example $name also contains a variable
#then that variable may or may not be expanded before the synopsis field is processed)
#
#
#=cut
#
sub _expand_vars 
{
	my $this = shift ;

	# Get hash of fields
	my %fields = $this->vars() ;

print "_expand_vars()\n" if $this->{'debug'}>=2 ;

	# work through each field, create a list of those that have changed
	my %changed ;
	foreach my $field (sort keys %fields)
	{
		# Skip non-scalars
		next if ref($fields{$field}) ;

print " + check $field...\n" if $this->{'debug'}>=2 ;
		
		# First see if this contains a '$'
		$fields{$field} ||= "" ;
		my $ix = index $fields{$field}, '$' ; 
		if ($ix >= 0)
		{
print " + + got some vars in $field = $fields{$field}\n" if $this->{'debug'}>=2 ;
			# Do replacement
			$fields{$field} =~ s{
								     \$                         # find a literal dollar sign
								     \{{0,1}					# optional brace
								    (\w+)                       # find a "word" and store it in $1
								     \}{0,1}					# optional brace
								}{
								    no strict 'refs';           # for $$1 below
								    if (defined $fields{$1}) {
								        $fields{$1};            # expand global variables only
								    } else {
								        "\${$1}";  				# leave it
								    }
								}egx;


			# Add to list
			$changed{$field} = $fields{$field} ;

print " + + $field now = $fields{$field}\n" if $this->{'debug'}>=2 ;
		}
	}

	# If some have changed then set them
	if (keys %changed)
	{
		$this->set(%changed) ;
	}

print "_expand_vars() - done\n" if $this->{'debug'}>=2 ;

}

#----------------------------------------------------------------------------
#
#=item B<_expand_args()>
#
#Expand any variables in the args
#
#=cut
#
sub _expand_args 
{
	my $this = shift ;

	my $args_href = $this->{_args} ;
	my $args_names_href = $this->{_arg_names_hash} ;

	# get args
	my %values ;
	foreach my $arg (keys %$args_names_href)
	{
		$values{$arg} = $args_href->{$arg} if defined($args_href->{$arg}) ;
	}

	# get replacement vars
#	my @vars ;
#	my $app = $this->app ;
#	if ($app)
#	{
#		my %app_vars = $app->vars ;
#		push @vars, \%app_vars ;
#		my %opt_vars = $app->options() ;
#		push @vars, \%opt_vars ;
#	}
#	push @vars, \%ENV ;
	
#	## expand
#	$this->expand_keys(\%values, \@vars) ;
		
	## Update
	foreach my $arg (keys %$args_names_href)
	{
		$args_href->{$arg} = $values{$arg} if defined($args_href->{$arg}) ;
	}
	
}

#----------------------------------------------------------------------------
#
#=item B<_process_argv()>
#
#Processes the @ARGV array
#
#=cut
#
sub _process_argv
{
	my $this = shift ;

	my $argv_aref = $this->{argv} ;
	my @args = @$argv_aref ;
	$argv_aref = [] ;		# clear our args, rebuild the list as we process them
	my $idx = 0 ;

$this->_dbg_prt(["_process_argv() : args=", \@args]) ;
	
	# values
	my $args_href = $this->{_args} ;
	# details
	my $args_names_href = $this->{_arg_names_hash} ;
	
	my $dest_type ;
	my $arg_list = $this->{arg_names} ;
	foreach my $name (@$arg_list)
	{
		if ($args_names_href->{$name}{'dest_type'}) 
		{
			# set value
			$args_href->{$name} = [] ;	
		}	
	}
				
	foreach my $name (@$arg_list)
	{
		last unless @args ;
		my $arg = shift @args ;
		
		# set value
		$args_href->{$name} = $arg ;	
		push @$argv_aref, $arg ;
		
		# get this dest type
		$dest_type = $name if $args_names_href->{$name}{'dest_type'} ;

		++$idx ;
	}

	# If last arg specified as ARRAY, then convert  value to ARRAY ref
	if ($dest_type)
	{
		my $arg = $args_href->{$dest_type} ;
		$args_href->{$dest_type} = [] ;
		pop @$argv_aref ;

		## Handle wildcards (mainly to cope with Windoze)
		if ($arg =~ m/[\*\?]/)
		{
			my @files = glob("$arg") ;
			if (@files)
			{
				push @{$args_href->{$dest_type}}, @files ;
				push @$argv_aref, @files ;
				$arg = undef ;		
			}
		}

		if ($arg)
		{
			push @{$args_href->{$dest_type}}, $arg ;			
			push @$argv_aref, $arg ;
		}
		
	}

$this->_dbg_prt(["_process_argv() : args hash (so far)=", $args_href, "args now=", \@args]) ;
	
	# If there are any args left over, handle them
	foreach my $arg (@args)
	{
		# If last arg specified as ARRAY, then just add all ARGS
		if ($dest_type)
		{
			## Handle wildcards (mainly to cope with Windoze)
			if ($arg =~ m/[\*\?]/)
			{
				my @files = glob("$arg") ;
				if (@files)
				{
					push @{$args_href->{$dest_type}}, @files ;
					push @$argv_aref, @files ;
					$arg = undef ;		
				}
			}
			
			if ($arg)
			{
				push @{$args_href->{$dest_type}}, $arg ;			
				push @$argv_aref, $arg ;
			}
		}
		else
		{
			push @$argv_aref, $arg ;

			# create name
			my $name = sprintf "arg%d", $idx++ ;		
			
			# Create new entry
			my $href = $this->_new_arg_entry($name) ;
			$args_names_href->{$name} = $href ;
			
			# save arg in specified order
			push @$arg_list, $name ; 
	
			# set value
			$args_href->{$name} = $arg ;
			
		}

	}

	$this->{argv} = $argv_aref ;
}

#----------------------------------------------------------------------------
#
#=item B<_process_arg_spec($arg_spec)>
#
#Processes the arg specification string, returning:
#
#	($name, $arg_spec, $spec, $dest_type, $arg_type, $arg_direction, $arg_optional, $arg_append, $arg_mode)
#
#=cut
#
sub _process_arg_spec 
{
	my $this = shift ;
	my ($arg_spec) = @_ ;

$this->_dbg_prt(["arg: _process_arg_spec($arg_spec)"], 2)   ;

	my $developer_only = 0 ;

	# If arg starts with start char then remove it
	$arg_spec =~ s/^[\-\+\*]// ;
	
	# Get arg name
	my $name = $arg_spec ;
	if ($arg_spec =~ /[\'\"](\w+)[\'\"]/)
	{
		$name = $1 ;
		$arg_spec =~ s/[\'\"]//g ;
	}
	$name =~ s/\=.*$// ;

	my $spec = $arg_spec ;
	my $arg = "";
	if ($spec =~ s/\=(.*)$//)
	{
		$arg = $1 ;
	}
$this->_dbg_prt(["_process_arg_spec() set: pod spec=$spec arg=$arg\n"], 2) ;
	
	my $dest_type = "" ;
	if ($arg =~ /([\@\*])/i)
	{
		$dest_type = $1 ;
	}			
	
	my $arg_type = "" ;
	if ($arg =~ /([sfd])/i)
	{
		$arg_type = $1 ;
		if ($arg_type eq 's')
		{
			$spec .= " <string>" ;
		}
		elsif ($arg_type eq 'f')
		{
			$spec .= " <file>" ;
		}
		elsif ($arg_type eq 'd')
		{
			$spec .= " <dir>" ;
		}
	}

	my $arg_direction = "i" ;
	my $arg_append = "" ;
	if ($arg =~ /(i|<)/i)
	{
		$arg_direction = 'i' ;
		$spec .= " <input>" ;
	}
	elsif ($arg =~ /a|>>/i)
	{
		$arg_direction = 'o' ;
		$arg_append = "a" ;
		$spec .= " <output>" ;
	}
	elsif ($arg =~ /(o|>)/i)
	{
		$arg_direction = 'o' ;
		$spec .= " <output>" ;
	}
	
	my $arg_optional = 0 ;
	if ($arg =~ /\?/i)
	{
$this->_dbg_prt(["_process_arg_spec() set: optional\n"], 2) ;
		$arg_optional = 1 ;
	}	

	my $arg_mode = "" ;
	if ($arg =~ /b/i)
	{
		$arg_mode = 'b' ;
	}
	
$this->_dbg_prt(["_process_arg_spec() set: final pod spec=$spec arg=$arg\n"], 2) ;
				
	return ($name, $arg_spec, $spec, $dest_type, $arg_type, $arg_direction, $arg_optional, $arg_append, $arg_mode) ;
}


#----------------------------------------------------------------------------
#
#=item B<_new_arg_entry($name, $arg_spec, $summary, $description, $default_val, $pod_spec, $arg_type, $arg_direction, $dest_type, $optional, $arg_append, $arg_mode)>
#
#Create a new HASH with the specified values. Sets the values to defaults if not specified
#
#=cut
#
sub _new_arg_entry
{
	my $this = shift ;
	my ($name, $arg_spec, $summary, $description, $default_val, $pod_spec, $arg_type, $arg_direction, $dest_type, $optional, $arg_append, $arg_mode) = @_ ;
	
	$summary ||= "Arg" ;
	$description ||= "" ;
	$arg_type ||= "s" ;
	$arg_direction ||= "i" ;
	$dest_type ||= "" ;
	$optional ||= 0 ;
	$arg_spec ||= "$arg_type" ;
	$arg_append ||= "" ;
	$arg_mode ||= "" ;
	my $entry_href = 
	{
		'name'=>$name, 
		'spec'=>$arg_spec, 
		'summary'=>$summary, 
		'description'=>$description,
		'default'=>$default_val,
		'pod_spec'=>$pod_spec,
		'type' => $arg_type,
		'direction' => $arg_direction,
		'dest_type' => $dest_type,
		'optional' => $optional,
		'append' => $arg_append,
		'mode' => $arg_mode,
	} ;

	return $entry_href ;
}



#============================================================================================
# DATA
#============================================================================================

#----------------------------------------------------------------------------

=item B< data([$name]) >

Returns the lines for the named __DATA__ section as a string. If no name is specified
returns the first section. 

Returns undef if no data found, or no section with specified name

=cut

sub data
{
	my $this = shift ;
	my ($name, %vars) = @_ ;
	
	my $data_ref ;
	$name ||= "" ;
	
$this->_dbg_prt(["Data: data($name)\n"]) ;
	
	if ($name)
	{
		my $data_href = $this->{_data_hash} ;
$this->_dbg_prt(["Data HASH=", $data_href], 2) ;
		if (exists($data_href->{$name}))
		{
			$data_ref = $data_href->{$name} ;
$this->_dbg_prt([" + Found data for $name=", $data_ref]) ;
		}		
	}
	else
	{
		my $data_aref = $this->{_data} ;
		if (@$data_aref)
		{
			$data_ref = $data_aref->[0] ;
		}
		
	}

	return undef unless $data_ref ;
	
	return wantarray ? @$data_ref : join "\n", @$data_ref ;	
}

#----------------------------------------------------------------------------

=item B< Data([%args]) >

Alias to L</data>

=cut

*Data = \&data ;



#----------------------------------------------------------------------------

=item B<process_data()>

If caller package namespace has __DATA__ defined then use that information to set
up object parameters.


=cut

sub process_data
{
	my $this = shift ;
	
	my $package = $this->{'package'} ;

$this->_dbg_prt(["Data: Process data from package $package\n"]) ;

    local (*alias, *stash);             # a local typeglob

    # We want to get access to the stash corresponding to the package
    # name
	no strict "vars" ;
	no strict "refs" ;
    *stash = *{"${package}::"};  # Now %stash is the symbol table

$this->_dbg_prt(["Data: $package symbols=\n", \%stash], 5) ;

	if (exists($stash{'DATA'}))
	{
		my @data ;
		my %data ;
		my $data_aref = [] ;
		
		push @data, $data_aref ;
		
		*alias = $stash{'DATA'} ;

$this->_dbg_prt(["Reading __DATA__\n"]) ;

		## Read data in - first split into sections
		my $line ;
		my $data_num = 1 ;
		while (defined($line=<alias>))
		{
			chomp $line ;
$this->_dbg_prt(["DATA: $line\n"], 2) ;
			
			if ($line =~ m/^\s*__DATA__/)
			{
$this->_dbg_prt(["+ New __DATA__\n"], 2) ;
				# Start a new list
				$data_aref = [] ;
				push @data, $data_aref ;

$this->_dbg_prt(["+ Data list size=",scalar(@data),"\n"], 2) ;
				
				# default name
				my $name = sprintf "data%d", $data_num++ ;
				$data{$name} = $data_aref ;
				
				# Check for specified name
				if ($line =~ m/__DATA__\s*(\S+)/)
				{
					$name = $1 ;
					$data{$name} = $data_aref ;
$this->_dbg_prt(["+ + named __DATA__ : $name\n"], 2) ;
				}
			}
			elsif ($line =~ m/^\s*__END__/ )
			{
$this->_dbg_prt(["+ __END__\n"], 2) ;
				last ;
			}
			elsif ($line =~ m/^\s*__#/ )
			{
$this->_dbg_prt(["+ __# comment\n"], 2) ;
				# skip
			}
			else
			{
				push @$data_aref, $line ;
			}
		}
$this->_dbg_prt(["Gathered data=", \@data], 2) ;

		# Store
		$this->{_data} = \@data ;
		$this->{_data_hash} = \%data ;

$this->_dbg_prt(["Processing __DATA__\n"]) ;
		
		## Look at first section
		my $obj_settings=0;
		$data_aref = $data[0] ;
		my $field ;
		my @field_data ;
		foreach $line (@$data_aref)
		{

			if ($line =~ m/^\s*\[(\w+)\]/)
			{
				my ($new_field) = lc $1 ;
				
				# This is object settings, so need to remove from list
				$obj_settings=1;

				# Use the data found so far for this field
				$this->_handle_field($field, \@field_data) if $field ;
				
				# next field
				$field = $new_field ;
				@field_data = () ;

			}
			elsif ($field)
			{
				push @field_data, $line ;
			}
		}

		if ($field)
		{
			# Use the data found so far for this field
			$this->_handle_field($field, \@field_data) ;
		}

	}

	use strict "vars" ;
	use strict "refs" ;

	## get user settings
	my $options_aref = [@DEFAULT_OPTS] ;
	push @$options_aref, @{$this->{_user_options}} ;

	## set up internals
	
	# rebuild these
	my $options_href = {} ;
	my $get_options_aref = [] ;
	my $option_names_aref = [] ;

	# keep full details
	my $options_fields_href = {} ;


	## Cycle through options
	foreach my $option_entry_aref (@$options_aref)
	{
		my ($option_spec, $summary, $description, $default_val, $owner_pkg) = @$option_entry_aref ;
		
		## Process the option spec
		my ($field, $spec, $dest_type, $developer_only, $fields_aref, $arg_type) ;
		($field, $option_spec, $spec, $dest_type, $developer_only, $fields_aref, $arg_type) = 
			$this->_process_option_spec($option_spec) ;
		
		# Set default if required
		$options_href->{$field} = $default_val if (defined($default_val)) ;
		
		# Add to Getopt list
		push @$get_options_aref, $option_spec => \$options_href->{$field} ;
		
		# Create full entry
		$options_fields_href->{$field} = {
				'field'=>$field, 
				'spec'=>$option_spec, 
				'summary'=>$summary, 
				'description'=>$description,
				'default'=>$default_val,
				'pod_spec'=>$spec,
				'type' => $arg_type,
				'dest_type' => $dest_type,
				'developer' => $developer_only,
				'entry' => $option_entry_aref,
				'owner' => $owner_pkg,
		} ;
		
		# add to list of names
		push @$option_names_aref, $field ;
	}

	## Save
	$this->{_options_list} = $options_aref ;
	$this->{_options} = $options_href ;
	$this->{_get_options} = $get_options_aref ;
	$this->{_option_fields_hash} = $options_fields_href ;

$this->_dbg_prt(["Get options=", $get_options_aref]) ;

	$this->{option_names} = $option_names_aref ;

}



#----------------------------------------------------------------------------
#
#=item B<_handle_field($field_data_aref)>
#
#Set the field based on the accumlated data
#
#=cut
#
sub _handle_field 
{
	my $this = shift ;
	my ($field, $field_data_aref) = @_ ;

$this->_dbg_prt(["Data: _handle_field($field, $field_data_aref)\n"], 2) ;

	# Handle any existing field values
	if ($field eq 'options')
	{
		# Parse the data into options
		my @options = $this->_parse_options($field_data_aref) ;

$this->_dbg_prt(["Data: set app options\n"], 2) ;
		## set the options
		$this->_append_options(\@options) ;
	}
	elsif ($field eq 'args')
	{
		# Parse the data into args
		my @args = $this->_parse_options($field_data_aref) ;

$this->_dbg_prt(["Data: set app options\n"], 2) ;
		## Access the application's 'Options' feature to set the options
		$this->append_args(\@args) ;
	}
	else
	{
		# Glue the lines together and set the field
		my $data = join "\n", @$field_data_aref ;

		# Remove leading/trailing space
		$data =~ s/^\s+// ;
		$data =~ s/\s+$// ;

$this->_dbg_prt(["Data: set app field $field => $data\n"], 2) ;
			
		## Set field directly into application	
		$this->set($field => $data) ;
	}
}


#----------------------------------------------------------------------------
#
#=item B<_parse_options($data_aref)>
#
#Parses option definition lines(s) of the form:
# 
# -<opt>[=s]		Summary of option [default=<value>]
# Description of option
#
#Optional [default] specification that sets the option to the default if not otherwised specified.
#
#And returns an ARRAY in the format useable by the 'options' method. 
#
#=cut
#
sub _parse_options 
{
	my $this = shift ;
	my ($data_aref) = @_ ;

$this->_dbg_prt(["Data: _parse_options($data_aref)\n"], 2) ;

	my @options ;
	
	# Scan through the options specification to create a number of options entries
	my ($spec, $summary, $description, $default_val) ;
	foreach my $line (@$data_aref)
	{
		## Options specified as:
		#
		# -<name list>[=<opt spec>]  [\[default=<default value>\]]
		#
		# <name list>:
		#    <name>|'<name>'
		#
		# <opt spec> (subset of that supported by Getopt::Long):
		#    <type> [ <desttype> ]	
		# <type>:
		#	s = String. An arbitrary sequence of characters. It is valid for the argument to start with - or -- .
		#	i = Integer. An optional leading plus or minus sign, followed by a sequence of digits.
		#	o = Extended integer, Perl style. This can be either an optional leading plus or minus sign, followed by a sequence of digits, or an octal string (a zero, optionally followed by '0', '1', .. '7'), or a hexadecimal string (0x followed by '0' .. '9', 'a' .. 'f', case insensitive), or a binary string (0b followed by a series of '0' and '1').
		#	f = Real number. For example 3.14 , -6.23E24 and so on.
		#	
		# <desttype>:
		#   @ = store options in ARRAY ref
		#   % = store options in HASH ref
		# 
		if ($line =~ m/^\s*[\-\*\+]\s*([\'\"\w\|\=\%\@\+\{\:\,\}\-\_\>\<\*]+)\s+(.*?)\s*(\[default=([^\]]+)\]){0,1}\s*$/)
		{
			# New option
			my ($new_spec, $new_summary, $new_default, $new_default_val) = ($1, $2, $3, $4) ;

			my ($dbg_default, $dbg_defval) = ($new_default||"", $new_default_val||"") ;
			$this->_dbg_prt([" + spec: $new_spec,  summary: $new_summary,  default: $dbg_default, defval=$dbg_defval\n"], 2) ;

			# Allow default value to be specified with "" or ''
			if (defined($new_default_val))
			{
				$new_default_val =~ s/^['"](.*)['"]$/$1/ ;
			}

			# Save previous option			
			if ($spec)
			{
				# Remove leading/trailing space
				$description ||= '' ;
				$description =~ s/^\s+// ;
				$description =~ s/\s+$// ;

				push @options, [$spec, $summary, $description, $default_val] ;
			}
			
			# update current
			($spec, $summary, $default_val, $description) = ($new_spec, $new_summary, $new_default_val, '') ;
		}
		elsif ($spec)
		{
			# Add to description
			$description .= "$line\n" ;
		}
	}

	# Save option
	if ($spec)
	{
		# Remove leading/trailing space
		$description ||= '' ;
		$description =~ s/^\s+// ;
		$description =~ s/\s+$// ;

		push @options, [$spec, $summary, $description, $default_val] ;
	}
	
	return @options ;
}


#----------------------------------------------------------------------------
#
#=item B<_append_options($aref)>
#
#Add these user defined options to the list
#
#=cut
#
sub _append_options 
{
	my $this = shift ;
	my ($aref) = @_ ;

	my $options = $this->{_user_options} ;
	push @$options, @$aref ;
}

#----------------------------------------------------------------------------
#
#=item B<_process_option_spec($option_spec)>
#
#Processes the option specification string, returning:
#
#	($field, $option_spec, $spec, $dest_type, $developer_only, $fields_aref, $arg_type)
#
#=cut
#
sub _process_option_spec 
{
	my $this = shift ;
	my ($option_spec) = @_ ;

$this->_dbg_prt( ["option: _process_option_spec($option_spec)"] , 2) ;

	my $developer_only = 0 ;

	# <opt spec> (subset of that supported by Getopt::Long):
	#    <type> [ <desttype> ]	
	# <type>:
	#	s = String. An arbitrary sequence of characters. It is valid for the argument to start with - or -- .
	#	i = Integer. An optional leading plus or minus sign, followed by a sequence of digits.
	#	o = Extended integer, Perl style. This can be either an optional leading plus or minus sign, followed by a sequence of digits, or an octal string (a zero, optionally followed by '0', '1', .. '7'), or a hexadecimal string (0x followed by '0' .. '9', 'a' .. 'f', case insensitive), or a binary string (0b followed by a series of '0' and '1').
	#	f = Real number. For example 3.14 , -6.23E24 and so on.
	#	
	# <desttype>:
	#   @ = store options in ARRAY ref
	#   % = store options in HASH ref
		
	# If option starts with start char then remove it
	$option_spec =~ s/^[\-\+\*]// ;
	
	# if starts with dev: then remove and flag
	if ($option_spec =~ s/^dev://i)
	{
		$developer_only = 1 ;
	}
	
	# Get field name
	my $field = $option_spec ;
	if ($option_spec =~ /[\'\"](\w+)[\'\"]/)
	{
		$field = $1 ;
		$option_spec =~ s/[\'\"]//g ;
	}
	$field =~ s/\|.*$// ;
	$field =~ s/\=.*$// ;
	
	# re-create spec with field name highlighted
	my $spec = $option_spec ;
	my $arg = "";
	if ($spec =~ s/\=(.*)$//)
	{
		$arg = $1 ;
	}
$this->_dbg_prt( ["_process_option_spec() set: pod spec=$spec arg=$arg\n"], 2 ) ;

	my @fields = split /\|/, $spec ;
	if (@fields > 1)
	{
		# put field name first
		$spec = "$field" ;
		foreach my $fld (@fields)
		{
			next if $fld eq $field ;
			
	$this->_dbg_prt( [" + $fld\n"], 2 ) ;
			$spec .= '|' if $spec;
			$spec .= $fld ;
		}	
	}
	
	my $dest_type = "" ;
	if ($arg =~ /([\@\%])/i)
	{
		$dest_type = $1 ;
	}			

	my $arg_type = "" ;
	if ($arg =~ /([siof])/i)
	{
		$arg_type = $1 ;
		if ($arg_type eq 's')
		{
			if ($dest_type eq '%')
			{
				$spec .= " <key=value>" ;
			}
			else
			{
				$spec .= " <string>" ;
			}
		}
		elsif ($arg_type eq 'i')
		{
			$spec .= " <integer>" ;
		}
		elsif ($arg_type eq 'f')
		{
			$spec .= " <float>" ;
		}
		elsif ($arg_type eq 'o')
		{
			$spec .= " <extended int>" ;
		}
		else
		{
			$spec .= " <arg>"
		}
	}

$this->_dbg_prt( ["_process_option_spec() set: final pod spec=$spec arg=$arg\n"], 2 ) ;
				
	return ($field, $option_spec, $spec, $dest_type, $developer_only, \@fields, $arg_type) ;
			
}


#============================================================================================
# POD
#============================================================================================



#----------------------------------------------------------------------------

=item B<pod([$developer])>

Return full pod of application

If the optional $developer flag is set, returns application developer biased information

=cut

sub pod
{
	my $this = shift ;
	my ($developer) = @_ ;

	my $pod = 
		$this->pod_head($developer) .
		$this->pod_options($developer) .
		$this->pod_description($developer) .
		"\n=cut\n" ;
	return $pod ;
}	
	
#----------------------------------------------------------------------------

=item B<pod_head([$developer])>

Return pod heading of application

If the optional $developer flag is set, returns application developer biased information

=cut

sub pod_head
{
	my $this = shift ;
	my ($developer) = @_ ;

	my $name = $this->{name} ;
	my $summary = $this->{summary} ;
	my $synopsis = $this->get_synopsis() ;
	my $version = $this->{version} ;

	my $pod =<<"POD_HEAD" ;

${POD_HEAD}1 NAME

$name (v$version) - $summary

${POD_HEAD}1 SYNOPSIS

$synopsis

Options:

POD_HEAD

	# Cycle through
	my $names_aref = $this->{option_names} ;
	foreach my $option_name (@$names_aref)
	{
		my $option_entry_href = $this->option_entry($option_name) ;
		my $default = "" ;
		if ($option_entry_href->{'default'})
		{
			$default = "[Default: $option_entry_href->{'default'}]" ;
		}

		my $multi = "" ;
		if ($option_entry_href->{dest_type})
		{
			$multi = "(option may be specified multiple times)" ;
		}
				
		if ($developer)
		{
			$pod .= sprintf "       -%-20s $option_entry_href->{summary}\t$default\n", $option_entry_href->{'spec'} ;
		}
		else
		{
			# show option if it's not a devevloper option
			$pod .= sprintf "       -%-20s $option_entry_href->{summary}\t$default\t$multi\n", $option_entry_href->{'pod_spec'} 
				unless $option_entry_href->{'developer'} ;
		}
	}
	
	unless (@$names_aref)
	{
		$pod .= "       NONE\n" ;
	}

	return $pod ;
}

#----------------------------------------------------------------------------

=item B<pod_options([$developer])>

Return pod of options of application

If the optional $developer flag is set, returns application developer biased information

=cut

sub pod_options
{
	my $this = shift ;
	my ($developer) = @_ ;

	my $pod ="\n${POD_HEAD}1 OPTIONS\n\n" ;

	if ($developer)
	{
		$pod .= "Get options from application object as:\n   my \%opts = \$app->options();\n\n" ;
	}

	$pod .= "${POD_OVER} 8\n\n" ;


	# Cycle through
	my $names_aref = $this->{option_names} ;
	foreach my $option_name (@$names_aref)
	{
		my $option_entry_href = $this->option_entry($option_name) ;
$this->_dbg_prt(["entry for $option_name=",$option_entry_href]) ;
		my $default = "" ;
		if ($option_entry_href->{'default'})
		{
			$default = "[Default: $option_entry_href->{'default'}]" ;
		}

		my $show = 1 ;
		$show = 0  if ($option_entry_href->{'developer'} && !$developer) ;
		if ($show)
		{
			if ($developer)
			{
				$pod .= "=item -$option_entry_href->{spec} $default # Access as \$opts{$option_entry_href->{field}} \n" ;
			}
			else
			{
				$pod .= "=item B<-$option_entry_href->{pod_spec}> $default\n" ;
			}
			$pod .= "\n$option_entry_href->{description}\n" ;
			
			if ($option_entry_href->{dest_type})
			{
				$pod .= "This option may be specified multiple times.\n" ;
				
				if ($developer)
				{
					my $dtype = "" ;
					if ($option_entry_href->{dest_type} eq '@')
					{
						$dtype = 'ARRAY' ;
					}
					elsif ($option_entry_href->{dest_type} eq '%')
					{
						$dtype = 'HASH' ;
					}
					$pod .= "(The option values will be available internally via the $dtype ref \$opts{$option_entry_href->{field}})\n" ;
				}			
			}
			$pod .= "\n" ;
		}
	}

	unless (@$names_aref)
	{
		$pod .= "       NONE\n" ;
	}

	$pod .= "\n=back\n\n" ;

	return $pod ;
}


#----------------------------------------------------------------------------

=item B<pod_description([$developer])>

Return pod of description of application

If the optional $developer flag is set, returns application developer biased information

=cut

sub pod_description
{
	my $this = shift ;
	my ($developer) = @_ ;

	my $description = $this->{description} ;

	my $pod =<<"POD_DESC" ;

${POD_HEAD}1 DESCRIPTION

$description
  
POD_DESC
	
	return $pod ;
}


#----------------------------------------------------------------------------

=item B<get_synopsis()>

Check to ensure synopsis is set. If not, set based on application name and any Args
settings

=cut

sub get_synopsis 
{
	my $this = shift ;

	my $synopsis = $this->{synopsis} ;
	if (!$synopsis)
	{
		my %opts = $this->options() ;
		
		# start with basics
		my $app = $this->{name} ;
		$synopsis = "$app [options] " ;

		## Get args
		my $names_aref = $this->{arg_names} ;
		foreach my $arg_name (@$names_aref)
		{
			my $arg_entry_href = $this->arg_entry($arg_name) ;

			my $type = "" ;
			if ($arg_entry_href->{'type'} eq 'f')
			{
				$type = "file" ;
			}
			if ($arg_entry_href->{'type'} eq 'd')
			{
				$type = "directory" ;
			}

			if ($type)
			{
				my $direction = "input " ;
				if ($arg_entry_href->{'direction'} eq 'o')
				{
					$direction = "output " ;
				}
				$type = " ($direction $type)" ;
			}

			my $suffix = "" ;				
			if ($arg_entry_href->{'dest_type'})
			{
				$suffix = "(s)" ;
			}
	
			if ($arg_entry_href->{'optional'})
			{
				$synopsis .= 'I<[' ;
			}
			else
			{
				$synopsis .= 'B<' ;
			}
			
			$synopsis .= "{$arg_name$type$suffix}" ;
			$synopsis .= ']' if $arg_entry_href->{'optional'} ;
			$synopsis .= '> ' ;
		}
		
		
		# set our best guess
		$this->{synopsis} = $synopsis ;
	}	

	return $synopsis ;
}


#============================================================================================
# RUN
#============================================================================================

#-----------------------------------------------------------------------------

=item B<required([$required_href])>

Get/set the required programs list. If specified, B<$required_href> is a HASH ref where the 
keys are the names of the required programs (the values are unimportant).

This method returns the B<$required_href> HASH ref having set the values associated with the
program name keys to the path for that program. Where a program is not found then
it's path is set to undef.

Also, if the L</on_error> field is set to 'warning' or 'fatal' then this method throws a warning
or fatal error if one or more required programs are not found. Sets the message string to indicate 
which programs were not found. 

=cut

sub required
{
	my $this = shift ;
	my ($new_required_href) = @_ ;
	
	my $required_href = $this->{'required'} ;
	if ($new_required_href)
	{
		## Test for available executables
		foreach my $exe (keys %$new_required_href)
		{
			# only do this is we have File::Which
			if ($AVAILABLE_MOD{'File::Which'})
			{
				$required_href->{$exe} = which($exe) ;
			}
			else
			{
				$required_href->{$exe} = 1 ;
			}
		}
		
		## check for errors
		my $throw = $this->_throw_on_error($this->{on_error}) ;
		if ($throw)
		{
			my $error = "" ;
			foreach my $exe (keys %$new_required_href)
			{
				if (!$required_href->{$exe})
				{
					$error .= "  $exe\n" ;
				}
			}
			
			if ($error)
			{
				$this->$throw("The following programs are required but not available:\n$error\n") ;
			}
		}
	}
	
	return $required_href ;
}

#--------------------------------------------------------------------------------------------

=item B<run( [args] )>

Execute a command if B<args> are specified. Whether B<args> are specified or not, always returns the run object. 

This method has reasonably flexible arguments which can be one of:

=item (%args)

The args HASH contains the information needed to set the L</FIELDS> and then run teh command for example:

  ('cmd' => 'ping', 'args' => $host) 

=item ($cmd)

You can specify just the command string. This will be treated as if you had called the function with:

  ('cmd' => $cmd) 

=item ($cmd, $args)

You can specify the command string and the arguments string. This will be treated as if you had called the function with:

  ('cmd' => $cmd, 'args' => $args) 

NOTE: Need to get B<run> object from application to access this method. This can be done as one of:

  $app->run()->run(.....);
  
  or
  
  my $run = $app->run() ;
  $run->run(....) ;

=cut

sub run
{
	my $this = shift ;
	my (@args) = @_ ;

#	# See if this is a class call
#	$this = $this->check_instance() ;

$this->_dbg_prt(["run() this=", $this], 2) ;
$this->_dbg_prt(["run() args=", \@args]) ;

	my %args ;
	if (@args == 1)
	{
		$args{'cmd'} = $args[0] ;
	}
	elsif (@args == 2)
	{
		if ($args[0] ne 'cmd')
		{
			# not 'cmd' => '....' so treat as ($cmd, $args)
			$args{'cmd'} = $args[0] ;
			$args{'args'} = $args[1] ;
		}
		else
		{
			%args = (@args) ;
		}
	}
	else
	{
		%args = (@args) ;
	}
	
	## return immediately if no args
	return $this unless %args ;

	## create local copy of variables
	my %local = $this->vars() ;
	
	# Set any specified args
	foreach my $key (keys %local)
	{
		$local{$key} = $args{$key} if exists($args{$key}) ;
	}
	
	## set any 'special' vars
	my %set ;
	foreach my $key (qw/debug/)
	{
		$set{$key} = $args{$key} if exists($args{$key}) ;
	}
	$this->set(%set) if keys %set ;
	

	# Get command
	my $cmd = $local{'cmd'} ;
	$this->throw_fatal("command not specified") unless $cmd ;
	
	# Add niceness
	my $nice = $local{'nice'} ;
	if (defined($nice))
	{
		$cmd = "nice -n $nice $cmd" ;
	}
	
	
	# clear vars
	$this->set(
		'status'	=> 0,
		'results'	=> [],
		'error_str'	=> "",
	) ;
	

	# Check arguments
	my $args = $this->_check_run_args($local{'args'}) ;

	# Run command and save results
	my @results ;
	my $rc ;

	## Logging
	$this->_logging('cmd', "RUN: $cmd $args\n") ;

	my $timeout = $local{'timeout'} ;
	if ($local{'dryrun'})
	{
		## Print
		my $timeout_str = $timeout ? "[timeout after $timeout secs]" : "" ;
		print "RUN: $cmd $args $timeout_str\n" ;
	}
	else
	{
		## Run
		
		if (defined($timeout))
		{
			# Run command with timeout
			($rc, @results) = $this->_run_timeout($cmd, $args, $timeout, $local{'progress'}, $local{'check_results'}) ;		
		}
		else
		{
			# run command
			($rc, @results) = $this->_run_cmd($cmd, $args, $local{'progress'}, $local{'check_results'}) ;		
		}
	}

	# Update vars
	$this->{'status'} = $rc ;
	chomp foreach (@results) ;
	$this->{'results'} = \@results ;

	$this->_logging('results', \@results) ;
	$this->_logging('status', "Status: $rc\n") ;
	
	## Handle non-zero exit status
	my $throw = $this->_throw_on_error($local{'on_error'}) ;
	if ($throw && $rc)
	{
		my $results = join("\n", @results) ;
		my $error_str = $local{'error_str'} ;
		$this->$throw("Command \"$cmd $args\" exited with non-zero error status $rc : \"$error_str\"\n$results\n") ;
	}
	
	return($this) ;
}

#----------------------------------------------------------------------------

=item B< Run([%args]) >

Alias to L</run>

=cut

*Run = \&run ;

#--------------------------------------------------------------------------------------------

=item B<results()>

Run: Retrieve the results output from the last run. Results are returned as an ARRAY ref to the lines of
output

=cut

sub results
{
	my $this = shift ;

	return $this->{'results'} ;
}

#--------------------------------------------------------------------------------------------

=item B<status()>

Run: Retrieve the exit status of the last run.

=cut

sub status
{
	my $this = shift ;

	return $this->{'status'} ;
}

#--------------------------------------------------------------------------------------------

=item B<on_error( [$on_error] )>

Run: Set/get the on_error field.

=cut

sub on_error
{
	my $this = shift ;
	my ($on_error) = @_ ;
	
	$this->{'on_error'} = $on_error if (defined($on_error)) ;
	$on_error = $this->{'on_error'} ;
	
	return $on_error ;
}

#--------------------------------------------------------------------------------------------

=item B<progress( $progress_callback )>

Run: Set the progress callback.

=cut

sub progress
{
	my $this = shift ;
	my ($progress) = @_ ;
	
	$this->{'progress'} = $progress if (defined($progress)) ;
	$progress = $this->{'progress'} ;
	
	return $progress ;
}

#----------------------------------------------------------------------------
# logging with checks
sub _logging
{
	my $this = shift ;
	my ($type, @args) = @_ ;

	my $logopts_href = $this->{'log'} ;

	# pass to logger if necessary
	if ($logopts_href->{all} || $logopts_href->{$type})
	{
		$this->logging(@args) ;
	}
}
		
		



#--------------------------------------------------------------------------------------------
#
# Ensure arguments are correct
#
sub _check_run_args
{
	my $this = shift ;
	my ($args) = @_ ;
	
	# If there is no redirection, just add redirect 2>1
	if (!$args || ($args !~ /\>/) )
	{
		$args .= " 2>&1" ;
	}
	
	return $args ;
}


#----------------------------------------------------------------------
# Run command with no timeout
#
sub _run_cmd
{
	my $this = shift ;
	my ($cmd, $args, $progress, $check_results) = @_ ;

$this->_dbg_prt(["_run_cmd($cmd) args=$args\n"]) ;
	
	my @results ;
	@results = `$cmd $args` ;
	my $rc = $? ;

	foreach (@results)
	{
		chomp $_ ;
	}

	# if it's defined, call the progress checker for each line
	if (defined($progress))
	{
		my $linenum = 0 ;
		my $state_href = {} ;
		foreach (@results)
		{
			&$progress($_, ++$linenum, $state_href) ;
		}
	}

	
	# if it's defined, call the results checker for each line
	$rc ||= $this->_check_results(\@results, $check_results) ;

	return ($rc, @results) ;
}

#----------------------------------------------------------------------
#Execute a command in the background, gather output, return status.
#If timeout is specified (in seconds), process is killed after the timeout period.
#
sub _run_timeout
{
	my $this = shift ;
	my ($cmd, $args, $timeout, $progress, $check_results) = @_ ;

$this->_dbg_prt(["_run_timeout($cmd) timeout=$timeout args=$args\n"]) ;

	## Timesout must be set
	$timeout ||= 60 ;

	# Run command and save results
	my @results ;

	# Run command but time it and kill it when timed out
	local $SIG{ALRM} = sub { 
		# normal execution
		die "timeout\n" ;
	};

	# if it's defined, call the progress checker for each line
	my $state_href = {} ;
	my $linenum = 0 ;

	# Run inside eval to catch timeout		
	my $pid ;
	my $rc = 0 ;
	my $endtime = (time + $timeout) ;
	eval 
	{
		alarm($timeout);
		$pid = open my $proc, "$cmd $args |" or $this->throw_fatal("Unable to fork $cmd : $!") ;

		while(<$proc>)
		{
			chomp $_ ;
			push @results, $_ ;

			++$linenum ;

			# if it's defined, call the progress checker for each line
			if (defined($progress))
			{
				&$progress($_, $linenum, $state_href) ;
			}

			# if it's defined, check timeout
			if (time > $endtime)
			{
				$endtime=0;
				last ;
			}
		}
		alarm(0) ;
		$rc = $? ;
print "end of program : rc=$rc\n" if $this->{'debug'} ;  
	};
	if ($@)
	{
		$rc ||= 1 ;
		if ($@ eq "timeout\n")
		{
print "timed out - stopping command pid=$pid...\n" if $this->{'debug'} ;
			# timed out  - stop command
			kill('INT', $pid) ;
		}
		else
		{
print "unexpected end of program : $@\n" if $this->{'debug'} ; 			
			# Failed
			alarm(0) ;
			$this->throw_fatal( "Unexpected error while timing out command \"$cmd $args\": $@" ) ;
		}
	}
	alarm(0) ;

print "exit program\n" if $this->{'debug'} ; 

	# if it's defined, call the results checker for each line
	$rc ||= $this->_check_results(\@results, $check_results) ;

	return($rc, @results) ;
}

#----------------------------------------------------------------------
# Check the results calling the check_results() hook if defined
#
sub _check_results
{
	my $this = shift ;
	my ($results_aref, $check_results) = @_ ;

	my $rc = 0 ;
	
	# If it's defined, run the check results hook
	if (defined($check_results))
	{
		$rc = &$check_results($results_aref) ;
	}

	return $rc ;
}


#----------------------------------------------------------------------
# If the 'on_error' setting is not 'status' then return the "throw" type
#
sub _throw_on_error
{
	my $this = shift ;
	my ($on_error) = @_ ;
	$on_error ||= $ON_ERROR_DEFAULT ;
	
	my $throw = "";
	if ($on_error ne 'status')
	{
		$throw = 'throw_fatal' ;
		if ($on_error =~ m/warn/i)
		{
			$throw = 'throw_warning' ;
		}
	}

	return $throw ;
}






#============================================================================================
# LOGGING
#============================================================================================

#----------------------------------------------------------------------------

=item B<logging($arg1, [$arg2, ....])>

Log the argument(s) to the log file iff a log file has been specified.

The list of arguments may be: SCALAR, ARRAY reference, HASH reference, SCALAR reference. SCALAR and SCALAR ref are printed
as-is without any extra newlines. ARRAY ref is printed out one entry per line with a newline added. The HASH ref is printed out
in the format produced by L<App::Framework::Base::Object::DumpObj>.


=cut

sub logging
{
	my $this = shift ;
	my (@args) = @_ ;

	my $tolog = "" ;
	foreach my $arg (@args)
	{
		if (ref($arg) eq 'ARRAY')
		{
			foreach (@$arg)
			{
				$tolog .= "$_\n" ;
			}
		}
		elsif (ref($arg) eq 'HASH')
		{
#			$tolog .= prtstr_data($arg) . "\n" ;
		}
		elsif (ref($arg) eq 'SCALAR')
		{
			$tolog .= $$arg ;
		}
		elsif (!ref($arg))
		{
			$tolog .= $arg ;
		}
		else
		{
#			$tolog .= prtstr_data($arg) . "\n" ;
		}
	}
		
	## Log
	my $logfile = $this->{logfile} ;
	if ($logfile)
	{
		## start if we haven't yet
		if (!$this->{_started})
		{
			$this->_start_logging() ;
		}

		open my $fh, ">>$logfile" or $this->throw_fatal("Error: unable to append to logfile \"$logfile\" : $!") ;
		print $fh $tolog ;
		close $fh ;
	}

	## Echo
	if ($this->{to_stdout})
	{
		print $tolog ;
	}

	return($this) ;
}


#----------------------------------------------------------------------------

=item B<echo_logging($arg1, [$arg2, ....])>

Same as L</logging> but echoes output to STDOUT.

=cut

sub echo_logging
{
	my $this = shift ;
	my (@args) = @_ ;
	
	# Temporarily force echoing to STDOUT on, then do logging
	my $to_stdout = $this->{to_stdout} ;
	$this->{to_stdout} = 1 ;
	$this->logging(@args) ;
	$this->{to_stdout} = $to_stdout ;

	return($this) ;
}	
	
#----------------------------------------------------------------------------

=item B< Logging([%args]) >

Alias to L</logging>

=cut

*Logging = \&logging ;


#----------------------------------------------------------------------------
#
#=item B<_start_logging()>
#
#Create/append log file
#
#=cut
#
sub _start_logging
{
	my $this = shift ;

	my $logfile = $this->{logfile} ;
	if ($logfile)
	{
		my $mode = ">" ;
		if ($this->{mode} eq 'append')
		{
			$mode = ">>" ;
		}
		
		open my $fh, "$mode$logfile" or $this->throw_fatal("Unable to write to logfile \"$logfile\" : $!") ;
		close $fh ;
		
		## set flag
		$this->{_started} = 1 ;
	}
}	

#============================================================================================
# UTILITY
#============================================================================================


#----------------------------------------------------------------------------

=item B<expand_keys($hash_ref, $vars_aref)>

Processes all of the HASH values, replacing any variables with their contents. The variable
values are taken from the ARRAY ref I<$vars_aref>, which is an array of hashes. Each hash
containing variable name / variable value pairs.

The HASH values being expanded can be either scalar, or an ARRAY ref. In the case of the ARRAY ref each
ARRAY entry must be a scalar (e.g. an array of file lines).

=cut

sub expand_keys
{
	my $this = shift ;
	my ($hash_ref, $vars_aref, $_state_href, $_to_expand) = @_ ;

print "expand_keys($hash_ref, $vars_aref)\n" if $this->{debug};
$this->prt_data("vars=", $vars_aref, "hash=", $hash_ref) if $this->{debug} ;

	my %to_expand = $_to_expand ? (%$_to_expand) : (%$hash_ref) ;
	if (!$_state_href)
	{
		## Top-level
		my %data_ref ;
		
		# create state HASH
		$_state_href = {} ;
		
		# scan through hash looking for variables
		%to_expand = () ;
		foreach my $key (keys %$hash_ref)
		{
			my @vals ;
			if (ref($hash_ref->{$key}) eq 'ARRAY')
			{
				@vals = @{$hash_ref->{$key}} ;
			}
			elsif (!ref($hash_ref->{$key}))
			{
				push @vals, $hash_ref->{$key} ;
			}
			
			## Set up state - provide a level of indirection so that we can handle the case where multiple keys point to the same data
			my $ref = $hash_ref->{$key} || '' ;
			if ($ref && exists($data_ref{"$ref"}))
			{
print " + already seen data for key=$key\n" if $this->{debug}>=2;
				# already got created a state for this data, point to it 
				$_state_href->{$key} = $data_ref{"$ref"} ;
			}
			else
			{
print " + new state key=$key\n" if $this->{debug}>=2;
				my $state = 'expanded' ;
				$_state_href->{$key} = \$state ;
			}

			# save data reference
			$data_ref{"$ref"} = $_state_href->{$key} if $ref ;
			
print " + check for expansion...\n" if $this->{debug}>=2;
			foreach my $val (@vals)
			{
				next unless $val ;

print " + + val=$val\n" if $this->{debug}>=2;

				if (index($val, '$') >= 0)
				{
print " + + + needs expanding\n" if $this->{debug}>=2;
					$to_expand{$key}++ ;
					${$_state_href->{$key}} = 'to_expand' ;
					last ;
				}
			}
		}
	}

$this->prt_data("to expand=", \%to_expand) if $this->{debug};

$this->prt_data("Hash=", $hash_ref) if $this->{debug};

	## Expand them
	foreach my $key (keys %to_expand)
	{
	print " # Key=$key State=${$_state_href->{$key}}\n" if $this->{debug};
	
		# skip if not valid (if called recursively with a variable that is not in the hash)
		next unless exists($hash_ref->{$key}) ;

		# Do replacement iff required
		next if ${$_state_href->{$key}} eq 'expanded' ;

		my @vals ;
		if (ref($hash_ref->{$key}) eq 'ARRAY')
		{
			foreach my $val (@{$hash_ref->{$key}})
			{
				push @vals, \$val ;
			}
		}
		elsif (!ref($hash_ref->{$key}))
		{
			push @vals, \$hash_ref->{$key} ;
		}
		
		# mark as expanding
		${$_state_href->{$key}} = 'expanding' ;		

$this->prt_data("Vals to expand=", \@vals) if $this->{debug};

#use re 'debugcolor' ;

		foreach my $val_ref (@vals)
		{

	print " # Expand \"$$val_ref\" ...\n" if $this->{debug};

			$$val_ref =~ s{
							(?:
								[\\\$]\$					# escaped dollar
							     \{{0,1}					# optional brace
							    ([\w\-\d]+)                 # find a "word" and store it in $1
							     \}{0,1}					# optional brace
						    )
							|
							(?:
							     \$                         # find a literal dollar sign
							     \{{0,1}					# optional brace
							    ([\w\-\d]+)                 # find a "word" and store it in $1
							     \}{0,1}					# optional brace
						     )
						}{
							my $prefix = '' ;
							my ($escaped, $var) = ($1, $2) ;
	
							$escaped ||= '' ;
							$var ||= '' ;
							
	print " # esc=\"$escaped\", prefix=\"$prefix\", var=\"$var\"\n" if $this->{debug};
							
							my $replace='' ;
							if ($escaped)
							{
								$prefix = '$' ;
								$replace = $escaped ;
	print " ## escaped prefix=$prefix replace=$replace\n" if $this->{debug};
	print " ## DONE\n" if $this->{debug};
							}
							else
							{		
								## use current HASH values before vars				
							    if (defined $hash_ref->{$var}) 
							    {
print " ## var=$var current state=${$_state_href->{$var}}\n" if $this->{debug};
							    	if (${$_state_href->{$var}} eq 'to_expand')
							    	{
print " ## var=$var call expand..\n" if $this->{debug};
							    		# go expand it first
							   			$this->expand_keys($hash_ref, $vars_aref, $_state_href, {$var => 1}) ; 		
							    	}
							    	if (${$_state_href->{$var}} eq 'expanded')
							    	{
print " ## var=$var already expanded\n" if $this->{debug};
								        $replace = $hash_ref->{$var};            # expand variable
							    		$replace = join("\n", @{$hash_ref->{$var}}) if (ref($hash_ref->{$var}) eq 'ARRAY') ;
							    	}
							    }
print " ## var=$var  can replace from hash=$replace\n" if $this->{debug};
	
								## If not found, use vars
								if (!$replace)
								{
									## use vars 
									foreach my $href (@$vars_aref)
									{
									    if (defined $href->{$var}) 
									    {
									        $replace = $href->{$var};            # expand variable
								    		$replace = join("\n", @{$hash_ref->{$var}}) if (ref($href->{$var}) eq 'ARRAY') ;
		print " ## found var=$var replace=$replace\n" if $this->{debug};
									        last ;
									    }
									}					    
								}
print " ## var=$var  can replace now=$replace\n" if $this->{debug};

								if (!$replace)
								{
									$replace = "" ;
	print " ## no replacement\n" if $this->{debug};
	print " ## DONE\n" if $this->{debug};
								}
							}
													
	print " ## ALL DONE $key: $escaped$var = \"$prefix$replace\"\n\n" if $this->{debug};
							"$prefix$replace" ;
						}egxm;	## NOTE: /m is for multiline anchors; /s is for multiline dots
		}

$this->prt_data("Hash now=", $hash_ref) if $this->{debug}>=2;

		# mark as expanded
		${$_state_href->{$key}} = 'expanded' ;		

$this->prt_data("State now=", $_state_href) if $this->{debug}>=2;
	}
}

#----------------------------------------------------------------------------

=item B<throw_fatal($message)>

Output error message then exit

=cut

sub throw_fatal
{
	my $this = shift ;
	my ($message, $errorcode) = @_ ;

	print "Fatal Error: $message\n" ;
	$this->exit( $errorcode || 1 ) ;
}

#-----------------------------------------------------------------------------

=item B<throw_nonfatal($message, [$errorcode])>

Add a new error (type=nonfatal) to this object instance, also adds the error to this Class list
keeping track of all runtime errors

=cut

sub throw_nonfatal
{
	my $this = shift ;
	my ($message, $errorcode) = @_ ;
	
	print "Non-Fatal Error: $message\n" ;
	return ($errorcode || 0) ;
}

#-----------------------------------------------------------------------------

=item B<throw_warning($message, [$errorcode])>

Add a new error (type=warning) to this object instance, also adds the error to this Class list
keeping track of all runtime errors

=cut

sub throw_warning
{
	my $this = shift ;
	my ($message, $errorcode) = @_ ;
	
	print "Warning: $message\n" ;
	return ($errorcode || 0) ;
}

#-----------------------------------------------------------------------------

=item B<throw_note($message, [$errorcode])>

Add a new error (type=note) to this object instance, also adds the error to this Class list
keeping track of all runtime errors

=cut

sub throw_note
{
	my $this = shift ;
	my ($message, $errorcode) = @_ ;
	
	print "Info: $message\n" ;
	return ($errorcode || 0) ;
}

#----------------------------------------------------------------------------

=item B< find_lib($module) >

Looks for the named module in the @INC path. If found, checks the package name inside the file
to ensure that it really matches the capitalisation.

(Mainly for Microsoft Windows use!)

=cut

sub find_lib
{
	my $class = shift ;
	my ($module, $file_ref) = @_ ;

	my @module_dirs = split /::/, $module ;
	my $pm = pop @module_dirs ;

#print "find_lib($module)\n" ;
	
	my $found ;
	foreach my $dir (@INC)
	{
		my $file = File::Spec->catfile($dir, @module_dirs, "$pm.pm") ;

#print " + checking $file\n" ;
		if (-f $file)
		{
			if (open my $fh, "<$file")
			{
				my $line ;
				while (defined($line = <$fh>))
				{
					chomp $line ;
					if ($line =~ m/^\s*package\s+$module\s*;/)
					{
						if ($file_ref)
						{
							$file =~ s%\\%/%g ;
							$$file_ref = $file ;	
						}
						$found = $module ;
						last ;
					}
				}
				close $fh ;
			}
			last if $found ;
		}
	}

#print "find_lib() = $found\n" ;

	return $found ;
}


#@NO-EMBED BEGIN

#----------------------------------------------------------------------------
sub _module_to_embed
{
	my $this = shift @_ ;
	my ($module, $file, $embed_libs) = @_ ;
	
	my $embed_it = 0 ;

	## Always embed this module
	if ($module eq 'App::Framework::Lite')
	{
		$embed_it = 1 ;
	}
	elsif ($embed_libs)
	{
		# is this an App::Framework module
		if ($module =~ /^App::Framework::Lite/)
		{
			$embed_it = 1 ;
		}
		else
		{
			# is this module under the program directory? i.e. a user module
			my $regexp = qr($this->{'progpath'}) ;
			if ($file =~ $regexp)
			{
				$embed_it = 1 ;
			}
		}
	}

	return $embed_it ;
}

#----------------------------------------------------------------------------

=item B< embed($src, $dest, [$compress]) >

Embeds App::Framework::Lite into the script and writes the standalone script out

=cut

sub embed
{
	my $this = shift ;
	my ($src, $dest, $compress, $embed_libs) = @_ ;

	my %libs ;
	my %handled_libs ;
	my @main ;

print "embed($src, $dest, compress=$compress, embed_libs=$embed_libs)\n" if $this->{'debug'};

	## Handle source
	open my $in_fh, "<$src" or die "Error: Unable to read $src : $!" ;
	open my $out_fh, ">$dest" or die "Error: Unable to write $dest : $!" ;

	my $perl_line = "";
	my $strict = "";
	my $line ;
	while(defined($line = <$in_fh>))
	{
		chomp $line ;

print "LINE: $line\n" if $this->{'debug'};

		if ($line =~ /^__DATA__/)
		{
			print $out_fh <<EMBED_START;
$perl_line
##################################################################################
# Start of embedded modules - embedded by App::Framework::Lite
#
# Your original script is now at the end of the file.
#
##################################################################################
#
$strict
EMBED_START
			
			# Handle any other embedded modules
			foreach my $mod (sort {$libs{$a}{'order'} <=> $libs{$b}{'order'} } keys %libs)
			{
				my $module_str = $libs{$mod}{'content'} ;
				
				print $out_fh "\n## EMBEDDED $mod ##\n" ;
				print $out_fh "$module_str\n" ;
				print $out_fh "\## EMBEDDED $mod - END ##\n" ;
			}
			
			print $out_fh <<EMBED_END;
#
##################################################################################
# End of embedded modules - embedded by App::Framework::Lite
##################################################################################
package main;

EMBED_END

#			print $out_fh "\n$line\n" ;
			push @main, "\n$line\n" ;
		}
		else
		{
			if (!$perl_line)
			{
				# find first line (if specifed)
				if ($line =~ /^#!/)
				{
					$perl_line = $line ;
				}	
			}
			
			## Check for libs if required
			if ($line =~ /^\s*use\s+(\S+)(.*);/)
			{
				my ($module, $import, $file) = ($1, $2, undef) ;
				if ($module eq 'strict')
				{
					$strict = $line ;
				}
				$module = $this->find_lib($module, \$file) ;
				
				
				# If this is related to the program path then include it
				if ($this->_module_to_embed($module, $file, $embed_libs))
				{
					push @main, "$module->import($import) ;\n" ;

print " + get subs\n" if $this->{'debug'};
					## get any sub-modules
					my @new = ($module) ;
					my $new = 1 ;
					do
					{
						$new = 0 ;
						foreach my $mod (keys %libs)
						{
							if (!$handled_libs{$mod})
							{
								push @new, $mod ;
							}
						}
						foreach my $mod (@new)
						{
print " + + module str $mod\n" if $this->{'debug'};
							my $href = $this->_add_mod_lib($mod, \%libs) ;
							$href->{'content'} = $this->_module_str($mod, $compress, \%libs, $embed_libs) ;
							++$handled_libs{$mod} ;
							++$new ;
						}
						@new = () ;
					} while ($new) ;
print " + get subs done\n" if $this->{'debug'};
					
					next ;
				}
			}
#			print $out_fh "$line\n" ;
			push @main, "$line\n" ;
		}
	}
	close $in_fh ;
	
	# output script body
	foreach my $line (@main)
	{
		print $out_fh "$line" ;
	}	
	close $out_fh ;	
	
	return %libs ;
}
#@NO-EMBED END


#============================================================================================
# PRIVATE
#============================================================================================

#@NO-EMBED BEGIN

#---------------------------------------------------------------------
# Squash module down to a few lines of text
sub _module_str
{
	my $this = shift ;
	my ($module, $compress, $libs_href, $embed_libs) = @_ ;
	
	my $module_str = "" ;

print "_module_str($module, compress=$compress, embed_libs=$embed_libs)\n" if $this->{'debug'};
	
	## Find module file
	my $src ;
	$this->find_lib($module, \$src) ;
	
	## Squash module
	open my $in_fh, "<$src" or die "Error: Unable to read module $src : $!" ;
	my $use=0 ;
	my $begin=0 ;
	my $complete=0;
	my $pod=0 ;
	my $podnext=0 ;
	my $no_embed=0 ;
	my $asis=0 ;
	my $prev_semi=0;
	my $comment=0;
	my $varinit = 1 ;
	my $varsdef = "" ;
	my $line ;
	my $current_len = 0 ;
	
	$asis = '@@ALWAYS-ASIS@@' if !$compress ;
	
	while(defined($line = <$in_fh>))
	{
		chomp $line ;

print " : LINE: $line\n" if $this->{'debug'};
print " (varinit=$varinit, pod=$pod)\n" if $this->{'debug'};

		next if $complete ;

		if ($line =~ /\@NO\-EMBED (\w+)/)
		{
			if ($1 eq 'BEGIN')
			{
				$no_embed = 1 ;
			}
			else
			{
				$no_embed = 0 ;
			}
			next ;
		}
		next if $no_embed ;

		## pod
		$pod = $podnext ;
		if ($line =~ /^=(\w+)/)
		{
			if ($1 eq 'cut')
			{
				$podnext = 0 ;
			}
			else
			{
				$podnext = 1 ;
			}
			$pod = 1 ;
		}

			
		## using an embdeddable module?
		$use=0 ;
		if (!$pod)
		{
			if ($line =~ /^\s*use\s+(\S+)(.*);/)
			{
				my ($module, $import, $file) = ($1, $2, undef) ;
				$module = $this->find_lib($module, \$file) ;
				$use=1 ;
	
	print " + use $module ($import)\n" if $this->{'debug'};
				
				# If this is embeddable
				if ($this->_module_to_embed($module, $file, $embed_libs))
				{
	print " + + embed $module\n" if $this->{'debug'} ;
					$module_str .= "$module->import($import) ;\n" ;
					$current_len = 0 ;
					$this->_add_mod_lib($module, $libs_href) ;
					next
				}
			}
		}


		if ($asis)
		{
			## Look for end of as-is block
			if ($line =~ /^$asis/)
			{
				$asis = 0 ;
				$module_str .= "$line\n" ;
				$current_len = 0 ;
print " + + line asis END\n" if $this->{'debug'};
				next ;
			}
		}
		else
		{
print " + + pod skip\n" if $pod && $this->{'debug'};
			next if $pod ;

			$line =~ s/^\s+// ;
			$line =~ s/\s+$// ;
			
print " + + empty line skip\n" if !$line && $this->{'debug'};
			next unless $line ;

print " + + comment line skip\n" if ($line =~ /^#/) && $this->{'debug'} ; 
			next if ($line =~ /^#/) ; 
			
			# check for code that needs to be kept "as-is"
			if ($line =~ /<<['"]*(\w+)['"]*/)
			{
				$asis = $1 ;
			}
		}


		if (!$pod)
		{
		# BEGIN block
		if ($line =~ /^\s*BEGIN/)
		{
			$begin=1 ;
	print " + BEGIN found\n" if $this->{'debug'};
		}
		if ($begin)
		{
			# end of variables section
			$varinit = 0 ;

	print " + BEGIN processing\n" if $this->{'debug'};
			if ($line =~ /{/)
			{
				$begin = 0 ;
				
	print " + BEGIN handle vars\n" if $this->{'debug'};
				## See if we've handled any variables
				if ($varsdef)
				{
	print " + BEGIN inserted vars\n$varsdef\n" if $this->{'debug'};
					# add variables
					$line =~ s/([^{]*\{)/$1 . $varsdef/e ;
					$varsdef = "" ;
				}
	print " + BEGIN done\n" if $this->{'debug'};
			}
		}
		
		# skip end of module
		if ($line =~ /^__END__|^1;/)
		{
print " + + line skip END\n" if $this->{'debug'};

			## See if we've handled any variables
			if ($varsdef)
			{
print " + + ADD BEGIN:\n$varsdef\n" if $this->{'debug'};
				$module_str .= "\nBEGIN {\n" ;
				$module_str .= $varsdef ;
				$module_str .= "}\n" ;
				$varsdef = "" ;
				$current_len = 0 ;
			}
			$complete=1 ;
			next ;
		}

		# end of variables section
		if ($line =~ /^\s*sub/)
		{
			# end of variables section
			$varinit = 0 ;
		}

		# comments
		$comment=0;
		if ($line =~ /#/) 
		{
			$comment=1 ;
		}
		
		# gather variables
		if ($varinit)
		{
	print " + Gathering variables\n" if $this->{'debug'};
			$line =~ s/^\s+// ;
			$line =~ s/\s+$// ;
			
			# don't keep: empty lines, package def, comments, pod, or use defs
			if ($line && ($line !~ /^package/) && ($line !~ /^#/) && !$pod && !$use)
			{
				# strip off our/my
				my $var = $line ;
				$var =~ s/^\s*(my|our)\s+// ;
#				$varsdef .= "$var\n" ;
				$varsdef .= "$var " ;
				$varsdef .= "\n" if $comment || $asis ;

	print " + + add var: $var\n" if $this->{'debug'};
			}
		}
		
		## Special case for App::Framework::Lite
		
		# Set embedded flag
		$line =~ s/\$EMBEDDED = 0/\$EMBEDDED = 1/ ;

		}
		
		## ensure we're not at the line limit
		my $line_len = length $line ;
		if ($current_len + $line_len >= $MAX_LINE_LEN)
		{
			$module_str .= "\n" ;
			$current_len = 0 ;
		}
		
		## print it
print " + + line ok\n" if $this->{'debug'};
		$module_str .= "$line" ;
		$current_len += $line_len ;

		if ($asis || $comment)
		{
			$module_str .= "\n" ;
			$current_len = 0 ;
		}
		else
		{
			$module_str .= " " ;
			++$current_len ;
		}
	}
	close $in_fh ;

print "_module_str($module) - END\n" if $this->{'debug'};

	return $module_str ;
}


#---------------------------------------------------------------------
# Add a module to the HASH
#
# HASH is indexed by module name, each entry is a HASH:
#
# 'order'	=> number # order in which modules have been added
# 'content' => scalar # text of the module
#
sub _add_mod_lib
{
	my $this = shift ;
	my ($module, $libs_href) = @_ ;

	my $href ;
	if (exists($libs_href->{$module}))
	{
		# already in the list
		$href = $libs_href->{$module} ;
	}
	else
	{
		my $order = scalar(%$libs_href) + 1 ;
		$href = {
			'order'		=> $order,
			'content'	=> "",
		} ;
		$libs_href->{$module} = $href ;
	}

	return $href ;
}

#@NO-EMBED END


#---------------------------------------------------------------------
sub _setup_modules
{
	my $this = shift ;

	## Set up optional routines

	# Attempt to load Debug object
	if (_load_module('Debug::DumpObj'))
	{
		# Create local function
		*prt_data = sub {my $this = shift; Debug::DumpObj::prt_data(@_)} ;
	}
	else
	{
		# See if we've got Data Dummper
		if (_load_module('Data::Dumper'))
		{
			# Create local function
			*prt_data = sub {my $this = shift; print Dumper([@_])} ;
		}	
		else
		{
			# Create local function
			*prt_data = sub {my $this = shift; print @_, "\n"} ;
		}
	}

}


#---------------------------------------------------------------------
sub _load_module
{
	my ($mod) = @_ ;
	
	my $ok = 1 ;

	# see if we can load up the packages for thumbnail support
	if (eval "require $mod") 
	{
		$mod->import() ;
	}
	else 
	{
		# Can't load package
		$ok = 0 ;
	}
	return $ok ;
}



#----------------------------------------------------------------------------
#
#=item B<_register_fn()>
#
#Register a function provided as a subroutine in the caller package as an app method
#in this object.
#
#Will only set the field value if it's not already set.
#
#=cut
#
sub _register_fn 
{
	my $this = shift ;
	my ($function, $alias) = @_ ;
	
	$alias ||= $function ;
	my $field_name ="${alias}_fn" ; 

	$this->_register_var('CODE', $function, $field_name) unless $this->{$field_name} ;
}


#----------------------------------------------------------------------------
#
#=item B<_register_scalar($external_name, $field_name)>
#
#Read the value of a variable in the caller package and copy that value as a data field
#in this object.
#
#Will only set the field value if it's not already set.
#
#=cut
#
sub _register_scalar 
{
	my $this = shift ;
	my ($external_name, $field_name) = @_ ;
	
	$this->_register_var('SCALAR', $external_name, $field_name) unless $this->{$field_name} ;
}

#----------------------------------------------------------------------------
#
#=item B<_register_var($type, $external_name, $field_name)>
#
#Read the value of a variable in the caller package and copy that value as a data field
#in this object. $type specifies the variable type: 'SCALAR', 'ARRAY', 'HASH', 'CODE'
# 
#NOTE: This method overwrites the field value irrespective of whether it's already set.
#
#=cut
#
sub _register_var 
{
	my $this = shift ;
	my ($type, $external_name, $field_name) = @_ ;

	my $package = $this->{package} ;

    local (*alias);             # a local typeglob

$this->_dbg_prt(["_register_var($type, $external_name, $field_name)\n"], 2) ;

    # We want to get access to the stash corresponding to the package
    # name
no strict "vars" ;
no strict "refs" ;
    *stash = *{"${package}::"};  # Now %stash is the symbol table

	if (exists($stash{$external_name}))
	{
		*alias = $stash{$external_name} ;

$this->_dbg_prt([" + found $external_name in $package\n"], 2) ;

		if ($type eq 'SCALAR')
		{
			if (defined($alias))
			{
				$this->set($field_name => $alias) ;
			}
		}
		if ($type eq 'ARRAY')
		{
			# Modified from - if (defined(@alias)) - because of "deprecated" error message 
			if (@alias)
			{
				$this->set($field_name => \@alias) ;
			}
		}
		if ($type eq 'HASH')
		{
			if (%alias)
			{
				$this->set($field_name => \%alias) ;
			}
		}
		elsif ($type eq 'CODE')
		{
			if (defined(&alias))
			{
$this->_dbg_prt([" + + Set $type - $external_name as $field_name\n"], 2) ;
				$this->set($field_name => \&alias) ;
			}
		}

	}
}


#----------------------------------------------------------------------------
#
#=item B<_exec_fn($function, @args)>
#
#Execute the registered function (if one is registered). Passes @args to the function.
# 
#=cut
#
sub _exec_fn
{
	my $this = shift ;
	my ($fn, @args) = @_ ;

	# Append _fn to function name, get the function, and call it if it's defined
	my $fn_name = "${fn}_fn" ;
	my $sub = $this->{$fn_name} || '' ;

#$this->_dbg_prt(["_exec_fn($fn) this=$this fn=$fn_name sub=$sub\n"], 2) ;

	&$sub(@args) if $sub ;
}


#----------------------------------------------------------------------------
#
#=item B<_dbg_prt($items_aref [, $min_debug])>
#
#Print out the items in the $items_aref ARRAY ref iff the calling object's debug level is >0. 
#If $min_debug is specified, will only print out items if the calling object's debug level is >= $min_debug.
#
#=cut
#
sub _dbg_prt
{
	my $obj = shift ;
	my ($items_aref, $min_debug) = @_ ;

	$min_debug ||= 1 ;
	
	## check debug level setting
	if ($obj->{debug} >= $min_debug)
	{
		my $pkg = ref($obj) ;
#		$pkg =~ s/App::Framework::Lite/ApFw/ ;
#		
#		my $prefix = App::Framework::Base::Object::DumpObj::prefix("$pkg ::  ") ;
		$obj->prt_data(@$items_aref) ;
#		App::Framework::Base::Object::DumpObj::prefix($prefix) ;
	}
}

#----------------------------------------------------------------------------
#
#=item B<set_paths($filename)>
#
#Get the full path to this application (follows links where required)
#
#=cut
#
sub _set_paths
{
	my $this = shift ;
	my ($filename) = @_ ;

	# Follow links
	$filename = File::Spec->rel2abs($filename) ;
	while ( -l $filename)
	{
		$filename = readlink $filename ;
	}
	
	# Get info
	my ($progname, $progpath, $progext) = fileparse($filename, '\.[^\.]+') ;
	$progpath =~ s%\\%/%g ;
	$progpath =~ s%^(.+)/$%$1%g ;
	if (ref($this))
	{
		# set if not class call
		$this->set(
			'progname'	=> $progname,
			'progpath'	=> $progpath,
			'progext'	=> $progext,
		) ;
	}

	# Set up include path to add script home + script home /lib subdir
	my %inc = map {$_=>1} @INC ;
	foreach my $path ($progpath, "$progpath/lib")
	{
		# add new paths
     	unshift(@INC,$path) unless exists $inc{$path} ;
     	$inc{$path} = 1 ;
		push @INC, $path unless exists $inc{$path} ;
	}
}

#----------------------------------------------------------------------------
#
#=item B<_show_data()>
#
#Show the __DATA__ defined in the main script. Run when option --dg-data is used
# 
#=cut
#
sub _show_data 
{
	my $this = shift ;
	my ($package) = @_ ;

#    local (*alias);             # a local typeglob
#
#    # We want to get access to the stash corresponding to the package
#    # name
#no strict "vars" ;
#no strict "refs" ;
#    *stash = *{"${package}::"};  # Now %stash is the symbol table
#
#	if (exists($stash{'DATA'}))
#	{
#		*alias = $stash{'DATA'} ;
#
#		print "## DATA ##\n" ;
#		my $line ;
#		while (defined($line=<alias>))
#		{
#			print "$line" ;
#		}
#		print "## DATA END ##\n" ;
#
#	}

print STDERR "Sorry, not implemented in Lite version\n" ;

}


#----------------------------------------------------------------------------
#
#=item B<_show_data_array()>
#
#Show data array (after processing the __DATA__ defined in the main script). 
#
#Run when option --debug-show-data-arry is used
# 
#=cut
#
sub _show_data_array
{
	my $this = shift ;

	my $data_aref = $this->_data() ;
	my $data_href = $this->_data_hash() ;
	
	# Get addresses from hash
	my %lookup = map { $data_href->{$_} => $_ } keys %$data_href ;
	
	# Show each data
	foreach my $data_ref (@$data_aref)
	{
		my $name = '' ;
		if (exists($lookup{$data_ref}))
		{
			$name = $lookup{$data_ref} ;
		}
		print "\n__DATA__ $name\n" ;
		
		foreach my $data (@$data_ref)
		{
			print "$data\n" ;
		}
		print "--------------------------------------\n" ;
	}

}

#----------------------------------------------------------------------------
# Output message, usage info, then exit
sub _complain_usage_exit
{
	my $this = shift ;
	my ($complain, $exit_code) = @_ ;

	print "Error: $complain\n" ;
	$this->usage() ;
	$this->exit( $exit_code || 1 ) ;
}



#########################################################################################################################################



=back

=head1 AUTHOR

Steve Price, C<< <sdprice at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-framework-lite at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Framework-Lite>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 TODO

This version actually contains support for the 'run' and 'logging' features (from L<App::Framework>) as experimental add-ons. Feel free
to use them, but don't expect any support yet!

The next release will have better documentation, feature support, testing etc. 


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Framework::Lite


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Framework-Lite>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Framework-Lite>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Framework-Lite>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Framework-Lite/>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2009 Steve Price, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

# ============================================================================================
# END OF PACKAGE
1;

__END__


