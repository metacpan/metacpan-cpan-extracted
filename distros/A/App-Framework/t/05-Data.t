#!/usr/bin/perl
#
use strict ;
use Test::More;

use App::Framework ;
use App::Framework::Base ;

# VERSION
our $VERSION = '2.00' ;

my $DEBUG=0;
my $VERBOSE=0;

	my $stdout="" ;
	my $stderr="" ;

	diag( "Testing data" );

my $NAMED1 =<<'NAMED1';
=head2 Named Arguments

The [NAMEARGS] section is used to specify the expected command line arguments used with the application. These "named arguments" provide
a mechanism for the framework to determine if all required arguments have been specified (generating an error message if not), creates
the application documentation showing these required arguments, and allows for easier access to the arguments in the application itself.

Along with specifying the name of arguments, specification of
certain properties of those arguments is provided for. 

Argument properties allow you to:
 * specify if arg is optional
 * specify if arg is a file/dir
 * specify if arg is expected to exist (autocheck existence; autocreate dir if output?)
 * specify if arg is an executable (autosearch PATH so don't need to specify full path?)
 * ?flag arg as an input or output (for filters, simple in/out scripts)?
 * ?specify arg expected to be a link?
NAMED1

my $NAMED2 =<<'NAMED2' ;
=head2 Options

The [OPTIONS] section is used to specify extra command line options for the application. The specification is used
both to create the code necessary to gather the option information (and provide it to the application), but also to
create application documentation (with the -help, -man options).

Each option specification is a multiline definition of the form:

   -option[=s]	Option summary [default=optional default]
 
   Option description
 
The -option specification can contain multiple strings separated by '|' to provide aliases to the same option. The first specified
string will be used as the option name. Alternatively, you may surround the preferred option name with '' quotes:

  -n|'number'=s
  
The option names/values are stored in a hash retrieved as $app->options():

  my %opts = $app->options();
  
Each option specification can optional append '=s' to the name to specify that the option expects a value (otherwise the option is treated
as a boolean flag), and a default value may be specified enclosed in '[]'.
NAMED2

my $NAMED3 =<<'NAMED3' ;
=head2 @INC path

App::Framework automatically pushes some extra directories at the start of the Perl include library path. This allows you to 'use' application-specific
modules without having to install them globally on a system. The path of the executing Perl application is found by following any links until
an actually Perl file is found. The @INC array has the following added:

	* $progpath
	* $progpath/lib
	
i.e. The directory that the Perl file resides in, and a sub-directory 'lib' will be searched for application-specific modules.
NAMED3

my $NAMED4 =<<'NAMED4' ;
App vars
05-Data
.t
main

Options vars
an opt1
this is new

Args vars
an arg
an opt1
this is new
NAMED4

my %NAMED = (
	'named1' => $NAMED1,
	'named2' => $NAMED2,
	'named3' => $NAMED3,
	'named4' => $NAMED4,

	'data1' => $NAMED1,
	'data2' => $NAMED2,
	'data3' => $NAMED3,
	'data4' => $NAMED4,
) ;
	
	plan tests => 2 * 2 * (keys %NAMED) ;

$App::Framework::Base::class_debug = 2 ;

	push @ARGV, ('-opt2', 'this is new') ;
	App::Framework->new()->go() ;


#=================================================================================
# SUBROUTINES EXECUTED BY APP
#=================================================================================

#sub ok {}
#sub diag {}

#----------------------------------------------------------------------
# Main execution
#
sub app
{
	my ($app) = @_ ;
	
	foreach my $name (sort keys %NAMED)
	{
		test_str($app, $name) ;
		test_array($app, $name) ;
	}
}




#=================================================================================
# SUBROUTINES
#=================================================================================

#----------------------------------------------------------------------
# Get data & check
#
sub test_str
{
	my ($app, $which) = @_ ;

print "test string : $which\n" ;
	my $named = $app->data($which) ;
	my $expected = $NAMED{$which} ;
	chomp $expected ; 
	is($named, $expected, "check $which text") ;

	$named = $app->Data($which) ;
	is($named, $expected, "check $which text (alias access)") ;
}

#----------------------------------------------------------------------
# check array version
#
sub test_array
{
	my ($app, $which) = @_ ;

print "test array : $which\n" ;

	my @NAMED = split "\n", $NAMED{$which} ;
	my @named = $app->data($which) ;
	
	is_deeply(\@named, \@NAMED, "check $which array") ;


	@named = $app->Data($which) ;
	is_deeply(\@named, \@NAMED, "check $which array (alias access)") ;
}


#=================================================================================
# SETUP
#=================================================================================
__DATA__

[SUMMARY]

Tests named data handling

[ARGS]

* arg1=s	Arg1 [default=an arg]
* arg2=s	Arg2 [default=$opt1]
* arg3=s	Arg3 [default=$opt2]

[OPTIONS]

-opt1=s		Opt1 [default=an opt1]
-opt2=s		Opt2 [default=an opt2]

[DESCRIPTION]

B<$name> does some stuff.

__#================================================================================
__DATA__ named1
=head2 Named Arguments

The [NAMEARGS] section is used to specify the expected command line arguments used with the application. These "named arguments" provide
a mechanism for the framework to determine if all required arguments have been specified (generating an error message if not), creates
the application documentation showing these required arguments, and allows for easier access to the arguments in the application itself.

Along with specifying the name of arguments, specification of
certain properties of those arguments is provided for. 

Argument properties allow you to:
 * specify if arg is optional
 * specify if arg is a file/dir
 * specify if arg is expected to exist (autocheck existence; autocreate dir if output?)
 * specify if arg is an executable (autosearch PATH so don't need to specify full path?)
 * ?flag arg as an input or output (for filters, simple in/out scripts)?
 * ?specify arg expected to be a link?
__#================================================================================
__DATA__ named2
=head2 Options

The [OPTIONS] section is used to specify extra command line options for the application. The specification is used
both to create the code necessary to gather the option information (and provide it to the application), but also to
create application documentation (with the -help, -man options).

Each option specification is a multiline definition of the form:

   -option[=s]	Option summary [default=optional default]
 
   Option description
 
The -option specification can contain multiple strings separated by '|' to provide aliases to the same option. The first specified
string will be used as the option name. Alternatively, you may surround the preferred option name with '' quotes:

  -n|'number'=s
  
The option names/values are stored in a hash retrieved as \$app->options():

  my %opts = \$app->options();
  
Each option specification can optional append '=s' to the name to specify that the option expects a value (otherwise the option is treated
as a boolean flag), and a default value may be specified enclosed in '[]'.
__#================================================================================
__DATA__ named3
=head2 @INC path

App::Framework automatically pushes some extra directories at the start of the Perl include library path. This allows you to 'use' application-specific
modules without having to install them globally on a system. The path of the executing Perl application is found by following any links until
an actually Perl file is found. The @INC array has the following added:

	* \$progpath
	* \$progpath/lib
	
i.e. The directory that the Perl file resides in, and a sub-directory 'lib' will be searched for application-specific modules.
__#================================================================================
__DATA__ named4
App vars
$progname
$progext
$package

Options vars
$opt1
$opt2

Args vars
$arg1
$arg2
$arg3
__#================================================================================