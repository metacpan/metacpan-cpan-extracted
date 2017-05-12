#!/usr/bin/perl
#
use strict ;
use Test::More;

use App::Framework ;

# VERSION
our $VERSION = '1.234' ;

my $DEBUG=0;
my $VERBOSE=0;

	my $stdout="" ;
	my $stderr="" ;

	diag( "Testing options expanded variables" );

	## run time options
	my %expected_options = (
		'test_name=s'		=> 'this is different',
		'default=s'			=> 'this is different',
		'default2=s'		=> 'my def',
		'default3=s'		=> 'my def another default',
		'log=s'				=> 'another default',
		'dbg-namestuff=s'	=> 'this is different this is different',
	) ;

	plan tests => 1 + 2*scalar(keys %expected_options) ;


#	@ARGV = ('-default', 'this is different') ;
	push @ARGV, ('-default', 'this is different') ;
	push @ARGV, ('-default2', 'my def') ;
	
	App::Framework->new(
		'feature_config' => {
			'Options' 	=> {'debug' => 2,},
			'Pod'	 	=> {'debug' => 2,},
		}
	)->go() ;


#=================================================================================
# SUBROUTINES EXECUTED BY APP
#=================================================================================

#----------------------------------------------------------------------
# Main execution
#
sub app
{
	my ($app, $opts_href, $args_href) = @_ ;
	
	# Check options
	my %opts = $app->options() ;

	# Check options alias
	my %opts2 = $app->Options() ;

	is_deeply(\%opts, \%opts2, "Access alias") ;
	
$app->prt_data("Options=", $opts_href) ;
$app->prt_data("Args=", $args_href) ;

	foreach my $optkey (keys %expected_options)
	{
		my $opt = $optkey ;
		my $num=1 ;
		if ($opt =~ /([\w\-]+)=/)
		{
			$opt = $1 ;
			$num=0;
		}
		ok(exists($opts{$opt}), "Test for $opt") ;
		is($opts{$opt}, $expected_options{$optkey}, "Test $opt value") ;



#		if ($num)
#		{
#			ok($opts{$opt} == $expected_options{$optkey}, "Test $opt value: got \"$opts{$opt}\" expected \"$expected_options{$optkey}\"") ;
#		}
#		else
#		{
#			ok($opts{$opt} eq $expected_options{$optkey}, "Test string $opt value: got \"$opts{$opt}\" expected \"$expected_options{$optkey}\"") ;
#		}
	}

	
}

#=================================================================================
# SUBROUTINES
#=================================================================================



#=================================================================================
# SETUP
#=================================================================================
__DATA__

[SUMMARY]

Tests options handling

[ARGS]

* series_name=s	Name of series [default=$test_name]
[OPTIONS]

-n|name|'test_name'=s		Test name [default=$default]

Specify a test name. This determines the output filenames (for the test script .ts and menu file .db).

Default action is to use the control file name (without file extension).

-nomacro	Do not create test macro calls

Normally the script automatically inserts a call to 'test_start' at the beginning of the test, and 'test_passed' at the end
of the test. In both cases, the macros are called with the quoted string that is the full 'path' of the test name. 

The test path being the menu names, separated by '::' down to the actual test name

-default=s		Default test [default="a default"]

Tests default setting

-default2=s		Default test2 [default=$test_name $default]

Tests default setting

-default3=s		Default test3 [default=$default2 $log]

Tests default setting

-log=s		Override default [default=another default]

Tests override of default setting

-dbg-namestuff=s	Name test [default=$test_name $default]

Tests the valid name of options

-dbg-name	Name test

Tests the valid name of options

[DESCRIPTION]

B<$name> does some stuff.

