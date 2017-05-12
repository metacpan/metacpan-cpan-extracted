#!/usr/bin/perl
#
use strict ;
use Test::More ;

use App::Framework ;

# VERSION
our $VERSION = '1.234' ;

my $DEBUG=0;
my $VERBOSE=0;

	my $stdout="" ;
	my $stderr="" ;

	diag( "Testing usage" );
	
	my @man = (
		'Must specify input file "source"',
		'-help|h               Print help',
		'-man                  Full documentation',
		'-name|n <arg>             Test name',
		'-nomacro              Do not create test macro calls',
		'-int <integer>        An integer',
		'-float <float>        An float',
		'-array <string>       An array           \(option may be specified multiple times\)',
		'-hash <key=value>     A hash             \(option may be specified multiple times\)',
	) ;

	my @expected = (
           '-verbose',             
           '-norun',            
           '-debug',            
           '-help',         
           '-man',         
	) ;


	## start with a redirect check
	eval{
		local *STDOUT ;
		local *STDERR ;

		open(STDOUT, '>', \$stdout)  or die "Can't open STDOUT: $!" ;
		open(STDERR, '>', \$stderr) or die "Can't open STDERR: $!";

		print "I was hoping for more!\n" ;
	} ;
	if (!$stdout)
	{
		diag("Sorry, can't redirect stdout: $@") ;
		plan skip_all => 'Unable to redirect stdout (I need to redirect to check the man pages)';
		exit 0 ;
	}
	else
	{
		## ok to run tests
		plan tests => scalar(@man) + scalar(@expected) ;
	}
	
	## Manual pages

	# Expect output (stdout):
	#
	#Error: Must specify input file "source"
	#Usage:
	#    01-Man [options] <source (input file)>
	#
	#    Options:
	#
	#           -debug=s              Set debug level    
	#           -h|help               Print help 
	#           -man                  Full documentation 
	#           -log|L=s              Log file   
	#           -v|verbose            Verbose output     
	#           -dryrun|norun         Dry run    
	#           -n|name=s             Test name  
	#           -nomacro              Do not create test macro calls
	#           -int <integer>        An integer
	#           -float <float>        An float
	#           -array <string>       An array           (option may be specified multiple times)
	#           -hash <key=value>     A hash             (option may be specified multiple times)	
	#
	eval{
		local *STDOUT ;
		local *STDERR ;

		open(STDOUT, '>', \$stdout)  or die "Can't open STDOUT: $!" ;
		open(STDERR, '>', \$stderr) or die "Can't open STDERR: $!";

		@ARGV = () ;	
		App::Framework->new('exit_type'=>'die')->go() ;
#		$app->go() ;
	} ;

print "App: $stdout\n\n" ;

	foreach my $test (@man)
	{
		like  ($stdout, qr/$test/im, "Man page entry existance: $test");
	}

	## expect these options once & only once
	foreach my $opt (@expected)
	{
		my $count = ($stdout =~ m/$opt/) ;
		is ($count, 1, "Single option $opt") ; 
	}



#=================================================================================
# SUBROUTINES EXECUTED BY APP
#=================================================================================

#----------------------------------------------------------------------
# Main execution
#
sub app
{
	my ($app) = @_ ;
	
}

#=================================================================================
# SUBROUTINES
#=================================================================================


#----------------------------------------------------------------------
sub split_man
{
	my ($man) = @_ ;
	
	my %man ;
	
	my $section ;
	foreach my $line (split "\n", $man)
	{
		if ($line =~ m/^(\S+)/)
		{
			$section = $1 ;
			$man{$section} ||= '' ;
		}
		else
		{
			$line =~ s/^\s+//;
			$line =~ s/\s+$//;
			next unless $line ;
			
			$man{$section} .= "$line\n" ;
		}
	}
	return %man ;
}

#=================================================================================
# SETUP
#=================================================================================
__DATA__

[SUMMARY]

Tests manual page creation

[ARGS]

* source=f		Source file

[OPTIONS]

-n|'name'=s		Test name

Specify a test name. This determines the output filenames (for the test script .ts and menu file .db).

Default action is to use the control file name (without file extension).

-nomacro	Do not create test macro calls

Normally the script automatically inserts a call to 'test_start' at the beginning of the test, and 'test_passed' at the end
of the test. In both cases, the macros are called with the quoted string that is the full 'path' of the test name. 

The test path being the menu names, separated by '::' down to the actual test name

-int=i		An integer

Example of integer option

-float=f	An float

Example of float option

-array=s@	An array

Example of an array option

-hash=s%	A hash

Example of a hash option


[DESCRIPTION]

B<$name> reads the control file to pull together fragments of test script. Creates a single test script file and a test menu.

