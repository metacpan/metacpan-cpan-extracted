#!/usr/bin/perl
#
use strict ;
use Test::More;

use File::Copy ;

use App::Framework ;

# VERSION
our $VERSION = '1.01' ;

my $DEBUG=0;
my $VERBOSE=0;

my $read_dir = "t/filter" ;
my $write_dir = "t/filter_wr" ;
my $source = 'source.txt' ;

my %expected = (
	'00-default'	=> {
		'args'		=> [
		],
		'input'		=> "$write_dir/$source",
		'output'	=> "$write_dir/default.txt",
	},
	'01-no_comment'	=> {
		'args'		=> [
			"-trim_comment",
			"-comment", '//',
		],
		'input'		=> "$write_dir/$source",
		'output'	=> "$write_dir/no_comment.txt",
	},
	'02-no_empty'	=> {
		'args'		=> [
			"-skip_empty",
		],
		'input'		=> "$write_dir/$source",
		'output'	=> "$write_dir/no_empty.txt",
	},
	'03-no_space'	=> {
		'args'		=> [
			"-trim_space",
		],
		'input'		=> "$write_dir/$source",
		'output'	=> "$write_dir/no_space.txt",
	},
	'04-terse'	=> {
		'args'		=> [
			"-trim_comment",
#			"-comment", "'#'",
			"-trim_space",
			"-skip_empty",
		],
		'input'		=> "$write_dir/$source",
		'output'	=> "$write_dir/terse.txt",
	},

) ;


	my $stdout="" ;
	my $stderr="" ;

	diag( "Testing filter extension - stdin/stdout" );

	plan tests => scalar(keys %expected) ;

	## clear out write path
	if (-d $write_dir)
	{
		foreach my $f (glob("$write_dir"))
		{
			unlink $f ;
		}
		rmdir $write_dir ;
	}
	mkdir $write_dir ;

	## Do it
	App::Framework->new(
		'feature_config' => {
			'Options' => {
				'debug' => $DEBUG,
			},
		},
	)->go() ;




#=================================================================================
# SUBROUTINES EXECUTED BY APP
#=================================================================================

#----------------------------------------------------------------------
# Main execution
#
sub app
{
	my ($app, $opts_href) = @_ ;

	print "Get internal data\n" ;
	foreach my $dtest (keys %expected)
	{
		#print "Get data $dtest\n" ;
		$expected{$dtest}{'data'} = $app->data($dtest) ;
		#print "Got data $expected{$dtest}{'data'}\n" ;
	}

	print "Get source data\n" ;
	my $source_data = getfile("$read_dir/$source") ;

	## run through tests
	print "Run tests\n" ;
	foreach my $test (sort keys %expected)
	{
		my $cmd = "$^X -Mblib t/test/filtertest.pl " ;
		$cmd .= join(' ', @{$expected{$test}{args}}) ;
		$cmd .= " >$expected{$test}{output}" ;

		print "Run \"$cmd\"\n" if $DEBUG ;

		open my $fh, "| $cmd" or die "Couldn't fork: $!\n";
		print $fh "$source_data\n";
		close $fh ;     
	}

	## check
	print "Check data\n" ;
	foreach my $test (sort keys %expected)
	{
		my $expected = $expected{$test}{'data'} ;
		my $got ;
		if ($expected{$test}{output})
		{
			$got = getfile($expected{$test}{output}) ;
		}
		else
		{
			$got = $stdout ;
		}
		chomp $got ;
		is($got, $expected, "Checking $test file contents") ;
	}



}

#=================================================================================
# SUBROUTINES
#=================================================================================

#----------------------------------------------------------------------
sub getfh
{
	my ($fh) = @_ ;
	local $/ = undef ;
	my $data = <$fh> ;
	return $data ;
}

#----------------------------------------------------------------------
sub getfile
{
	my ($file) = @_ ;
	print " getfile($file)\n" if $DEBUG ;
	open my $fh, "<$file" or die "Error: Unable to read file \"$file\" : $!";
	my $data = getfh($fh) ;
	close $fh ;
	return $data ;
}


#=================================================================================
# SETUP
#=================================================================================
__DATA__

[SUMMARY]

Tests file filter extension

[DESCRIPTION]

B<$name> does some stuff.

__#
__#-------------------------------------------------------------------------------------------------------
__DATA__ 00-default
#============================================================================================
# USES
#============================================================================================
USE FILE::PATH ;
USE FILE::BASENAME ;
USE FILE::SPEC ;
USE APP::FRAMEWORK::CORE ;


#============================================================================================
# OBJECT HIERARCHY
#============================================================================================
USE APP::FRAMEWORK::EXTENSION ;
OUR @ISA ;  // C++ TYPE COMMENT 

#============================================================================================
# GLOBALS
#============================================================================================

REVISION HISTORY FOR APP-FRAMEWORK

//0.07    SAT MAR 14 20:33:00 2009
//        BUG FIX: CORRECTED SQL INITIALISATION (WAS CLAIMING DBI NOT INSTALLED)
//        ADDED: -MAN-DEV OPTION TO DISPLAY APP DEVELOPER MAN PAGES
//        ADDED: ALLOW 'DEV:' PREFIX TO MAKE OPTION ONLY SHOW IN DEVELOPER MAN PAGES
//        ADDED: SQL SUPPORT FOR 'GROUP BY'

0.06    THU MAR 05 15:09:00 2009 // C++ TYPE COMMENT
        UPDATED SCRIPT POD. MODIFIED SO THAT SCRIPTS CAN BE USED WITHOUT DBI. CORRECTED BUILD FAIL WHEN DBI NOT INSTALLED.

0.05    WED MAR 04 13:29:00 2009
        CORRECTED MANIFEST PROBLEM THAT CAUSED T/04-ARGS.T TEST TO FAIL.

0.04    WED MAR 04 08:07:00 2009
        VARIOUS BUG FIXES.

0.03    TUE MAR 03 15:55:56 2009  // C++ TYPE COMMENT
        BETTER TESTING, BETTER DOCUMENTATION, VARIOUS BUG FIXES.

0.02    FRI FEB 27 08:38:56 2009
        FIXED MANIFEST.SKIP (AND MANIFEST).

0.01    THU FEB 26 15:51:56 2009
        FIRST VERSION, TESTING DISTRIBUTION FILES ARE CORRECT. THIS VERSION HAS VERY LIMITED TESTING.
__#
__#-------------------------------------------------------------------------------------------------------
__DATA__ 01-no_comment
#============================================================================================
# USES
#============================================================================================
USE FILE::PATH ;
USE FILE::BASENAME ;
USE FILE::SPEC ;
USE APP::FRAMEWORK::CORE ;


#============================================================================================
# OBJECT HIERARCHY
#============================================================================================
USE APP::FRAMEWORK::EXTENSION ;
OUR @ISA ;  

#============================================================================================
# GLOBALS
#============================================================================================

REVISION HISTORY FOR APP-FRAMEWORK







0.06    THU MAR 05 15:09:00 2009 
        UPDATED SCRIPT POD. MODIFIED SO THAT SCRIPTS CAN BE USED WITHOUT DBI. CORRECTED BUILD FAIL WHEN DBI NOT INSTALLED.

0.05    WED MAR 04 13:29:00 2009
        CORRECTED MANIFEST PROBLEM THAT CAUSED T/04-ARGS.T TEST TO FAIL.

0.04    WED MAR 04 08:07:00 2009
        VARIOUS BUG FIXES.

0.03    TUE MAR 03 15:55:56 2009  
        BETTER TESTING, BETTER DOCUMENTATION, VARIOUS BUG FIXES.

0.02    FRI FEB 27 08:38:56 2009
        FIXED MANIFEST.SKIP (AND MANIFEST).

0.01    THU FEB 26 15:51:56 2009
        FIRST VERSION, TESTING DISTRIBUTION FILES ARE CORRECT. THIS VERSION HAS VERY LIMITED TESTING.
__#
__#-------------------------------------------------------------------------------------------------------
__DATA__ 02-no_empty
#============================================================================================
# USES
#============================================================================================
USE FILE::PATH ;
USE FILE::BASENAME ;
USE FILE::SPEC ;
USE APP::FRAMEWORK::CORE ;
#============================================================================================
# OBJECT HIERARCHY
#============================================================================================
USE APP::FRAMEWORK::EXTENSION ;
OUR @ISA ;  // C++ TYPE COMMENT 
#============================================================================================
# GLOBALS
#============================================================================================
REVISION HISTORY FOR APP-FRAMEWORK
//0.07    SAT MAR 14 20:33:00 2009
//        BUG FIX: CORRECTED SQL INITIALISATION (WAS CLAIMING DBI NOT INSTALLED)
//        ADDED: -MAN-DEV OPTION TO DISPLAY APP DEVELOPER MAN PAGES
//        ADDED: ALLOW 'DEV:' PREFIX TO MAKE OPTION ONLY SHOW IN DEVELOPER MAN PAGES
//        ADDED: SQL SUPPORT FOR 'GROUP BY'
0.06    THU MAR 05 15:09:00 2009 // C++ TYPE COMMENT
        UPDATED SCRIPT POD. MODIFIED SO THAT SCRIPTS CAN BE USED WITHOUT DBI. CORRECTED BUILD FAIL WHEN DBI NOT INSTALLED.
0.05    WED MAR 04 13:29:00 2009
        CORRECTED MANIFEST PROBLEM THAT CAUSED T/04-ARGS.T TEST TO FAIL.
0.04    WED MAR 04 08:07:00 2009
        VARIOUS BUG FIXES.
0.03    TUE MAR 03 15:55:56 2009  // C++ TYPE COMMENT
        BETTER TESTING, BETTER DOCUMENTATION, VARIOUS BUG FIXES.
0.02    FRI FEB 27 08:38:56 2009
        FIXED MANIFEST.SKIP (AND MANIFEST).
0.01    THU FEB 26 15:51:56 2009
        FIRST VERSION, TESTING DISTRIBUTION FILES ARE CORRECT. THIS VERSION HAS VERY LIMITED TESTING.
__#
__#-------------------------------------------------------------------------------------------------------
__DATA__ 03-no_space
#============================================================================================
# USES
#============================================================================================
USE FILE::PATH ;
USE FILE::BASENAME ;
USE FILE::SPEC ;
USE APP::FRAMEWORK::CORE ;


#============================================================================================
# OBJECT HIERARCHY
#============================================================================================
USE APP::FRAMEWORK::EXTENSION ;
OUR @ISA ;  // C++ TYPE COMMENT

#============================================================================================
# GLOBALS
#============================================================================================

REVISION HISTORY FOR APP-FRAMEWORK

//0.07    SAT MAR 14 20:33:00 2009
//        BUG FIX: CORRECTED SQL INITIALISATION (WAS CLAIMING DBI NOT INSTALLED)
//        ADDED: -MAN-DEV OPTION TO DISPLAY APP DEVELOPER MAN PAGES
//        ADDED: ALLOW 'DEV:' PREFIX TO MAKE OPTION ONLY SHOW IN DEVELOPER MAN PAGES
//        ADDED: SQL SUPPORT FOR 'GROUP BY'

0.06    THU MAR 05 15:09:00 2009 // C++ TYPE COMMENT
UPDATED SCRIPT POD. MODIFIED SO THAT SCRIPTS CAN BE USED WITHOUT DBI. CORRECTED BUILD FAIL WHEN DBI NOT INSTALLED.

0.05    WED MAR 04 13:29:00 2009
CORRECTED MANIFEST PROBLEM THAT CAUSED T/04-ARGS.T TEST TO FAIL.

0.04    WED MAR 04 08:07:00 2009
VARIOUS BUG FIXES.

0.03    TUE MAR 03 15:55:56 2009  // C++ TYPE COMMENT
BETTER TESTING, BETTER DOCUMENTATION, VARIOUS BUG FIXES.

0.02    FRI FEB 27 08:38:56 2009
FIXED MANIFEST.SKIP (AND MANIFEST).

0.01    THU FEB 26 15:51:56 2009
FIRST VERSION, TESTING DISTRIBUTION FILES ARE CORRECT. THIS VERSION HAS VERY LIMITED TESTING.
__#
__#-------------------------------------------------------------------------------------------------------
__DATA__ 04-terse
USE FILE::PATH ;
USE FILE::BASENAME ;
USE FILE::SPEC ;
USE APP::FRAMEWORK::CORE ;
USE APP::FRAMEWORK::EXTENSION ;
OUR @ISA ;  // C++ TYPE COMMENT
REVISION HISTORY FOR APP-FRAMEWORK
//0.07    SAT MAR 14 20:33:00 2009
//        BUG FIX: CORRECTED SQL INITIALISATION (WAS CLAIMING DBI NOT INSTALLED)
//        ADDED: -MAN-DEV OPTION TO DISPLAY APP DEVELOPER MAN PAGES
//        ADDED: ALLOW 'DEV:' PREFIX TO MAKE OPTION ONLY SHOW IN DEVELOPER MAN PAGES
//        ADDED: SQL SUPPORT FOR 'GROUP BY'
0.06    THU MAR 05 15:09:00 2009 // C++ TYPE COMMENT
UPDATED SCRIPT POD. MODIFIED SO THAT SCRIPTS CAN BE USED WITHOUT DBI. CORRECTED BUILD FAIL WHEN DBI NOT INSTALLED.
0.05    WED MAR 04 13:29:00 2009
CORRECTED MANIFEST PROBLEM THAT CAUSED T/04-ARGS.T TEST TO FAIL.
0.04    WED MAR 04 08:07:00 2009
VARIOUS BUG FIXES.
0.03    TUE MAR 03 15:55:56 2009  // C++ TYPE COMMENT
BETTER TESTING, BETTER DOCUMENTATION, VARIOUS BUG FIXES.
0.02    FRI FEB 27 08:38:56 2009
FIXED MANIFEST.SKIP (AND MANIFEST).
0.01    THU FEB 26 15:51:56 2009
FIRST VERSION, TESTING DISTRIBUTION FILES ARE CORRECT. THIS VERSION HAS VERY LIMITED TESTING.
__#
__#-------------------------------------------------------------------------------------------------------
__DATA__ 99-inplace
#============================================================================================
# USES
#============================================================================================
USE FILE::PATH ;
USE FILE::BASENAME ;
USE FILE::SPEC ;
USE APP::FRAMEWORK::CORE ;
#============================================================================================
# OBJECT HIERARCHY
#============================================================================================
USE APP::FRAMEWORK::EXTENSION ;
OUR @ISA ;  
#============================================================================================
# GLOBALS
#============================================================================================
REVISION HISTORY FOR APP-FRAMEWORK
0.06    THU MAR 05 15:09:00 2009 
UPDATED SCRIPT POD. MODIFIED SO THAT SCRIPTS CAN BE USED WITHOUT DBI. CORRECTED BUILD FAIL WHEN DBI NOT INSTALLED.
0.05    WED MAR 04 13:29:00 2009
CORRECTED MANIFEST PROBLEM THAT CAUSED T/04-ARGS.T TEST TO FAIL.
0.04    WED MAR 04 08:07:00 2009
VARIOUS BUG FIXES.
0.03    TUE MAR 03 15:55:56 2009  
BETTER TESTING, BETTER DOCUMENTATION, VARIOUS BUG FIXES.
0.02    FRI FEB 27 08:38:56 2009
FIXED MANIFEST.SKIP (AND MANIFEST).
0.01    THU FEB 26 15:51:56 2009
FIRST VERSION, TESTING DISTRIBUTION FILES ARE CORRECT. THIS VERSION HAS VERY LIMITED TESTING.
__#
__#-------------------------------------------------------------------------------------------------------
__DATA__ 05-stdout
#============================================================================================
# USES
#============================================================================================
USE FILE::PATH ;
USE FILE::BASENAME ;
USE FILE::SPEC ;
USE APP::FRAMEWORK::CORE ;


#============================================================================================
# OBJECT HIERARCHY
#============================================================================================
USE APP::FRAMEWORK::EXTENSION ;
OUR @ISA ;  

#============================================================================================
# GLOBALS
#============================================================================================

REVISION HISTORY FOR APP-FRAMEWORK







0.06    THU MAR 05 15:09:00 2009 
        UPDATED SCRIPT POD. MODIFIED SO THAT SCRIPTS CAN BE USED WITHOUT DBI. CORRECTED BUILD FAIL WHEN DBI NOT INSTALLED.

0.05    WED MAR 04 13:29:00 2009
        CORRECTED MANIFEST PROBLEM THAT CAUSED T/04-ARGS.T TEST TO FAIL.

0.04    WED MAR 04 08:07:00 2009
        VARIOUS BUG FIXES.

0.03    TUE MAR 03 15:55:56 2009  
        BETTER TESTING, BETTER DOCUMENTATION, VARIOUS BUG FIXES.

0.02    FRI FEB 27 08:38:56 2009
        FIXED MANIFEST.SKIP (AND MANIFEST).

0.01    THU FEB 26 15:51:56 2009
        FIRST VERSION, TESTING DISTRIBUTION FILES ARE CORRECT. THIS VERSION HAS VERY LIMITED TESTING.
__#
__#-------------------------------------------------------------------------------------------------------
__DATA__ end

