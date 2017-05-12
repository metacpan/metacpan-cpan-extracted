#!/usr/bin/perl
#
use strict ;
use Test::More ;

use App::Framework ':Script +Run +Logging' ;

# VERSION
our $VERSION = '1.000' ;

$ENV{'PERL_EXE'} = $^X ;
my %tests = (
	'test1'		=> {
		'name'		=> 'No output',
		'options'	=> {},
	},
	'test2'		=> {
		'name'		=> 'Command',
		'options'	=> {'cmd'=>1},
	},
	'test3'		=> {
		'name'		=> 'Status',
		'options'	=> {'status'=>1},
	},
	'test4'		=> {
		'name'		=> 'Results',
		'options'	=> {'results'=>1},
	},
	'test5'		=> {
		'name'		=> 'All',
		'options'	=> {'all'=>1},
	},
) ;

plan tests => scalar(keys %tests) ;

my $FILE = 't/logfile.log' ;

	@ARGV = ('-log', $FILE) ;
	my $app = App::Framework->new();
	$app->go() ;


#=================================================================================
# SUBROUTINES EXECUTED BY APP
#=================================================================================

#----------------------------------------------------------------------
# Main execution
#
sub app
{
	my ($app) = @_ ;

	my $log = $app->feature("Logging") ;
	my $run = $app->feature('Run') ;
	$run->on_error('status') ;

	foreach my $test (sort keys %tests)
	{
		$app->Logging("== $tests{$test}{name} ==\n");
		$run->log($tests{$test}{options}) ;
		$app->Run("$^X t/test/runtest.pl") ;
		comp_log($app, $FILE, $test, $tests{$test}{name}) ;
	}

}

#=================================================================================
# SUBROUTINES
#=================================================================================

#----------------------------------------------------------------------
#
sub feature_check
{
	my ($app, $name) = @_ ;

	my $lc_name = lc $name ;
	
	my $feat1 = $app->feature($name) ;
	my $class1 = ref($feat1) ;
	
	is($class1, "App::Framework::Feature::$name", "$name feature class check") ;
	
	my $feat = $app->$lc_name ;
	my $class = ref($feat) ;
	is($feat, $feat1, "$name object check") ;

	my $feat2 = $app->$name ;
	is($feat, $feat2, "$name object check (access alias)") ;
}

#----------------------------------------------------------------------
#
sub comp_log
{
	my ($app, $logfile, $test, $name) = @_ ;

	# get log & strip out comments
	my $log_data = getfile($logfile) ;
	$log_data =~ s/#.*$//mg ;
	
	# get expected
	my $expected = $app->Data($test) ;
	
	is($log_data, $expected, "Log file comparison : $name") ;
}

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
	open my $fh, "<$file" ;
	my $data = getfh($fh) ;
	close $fh ;
	return $data ;
}


#=================================================================================
# SETUP
#=================================================================================
__DATA__

[SUMMARY]

Tests run feature

__DATA__ test1
== No output ==

__DATA__ test2
== No output ==
== Command ==
RUN: $PERL_EXE t/test/runtest.pl  2>&1

__DATA__ test3
== No output ==
== Command ==
RUN: $PERL_EXE t/test/runtest.pl  2>&1
== Status ==
Status: 0

__DATA__ test4
== No output ==
== Command ==
RUN: $PERL_EXE t/test/runtest.pl  2>&1
== Status ==
Status: 0
== Results ==
Hello world

__DATA__ test5
== No output ==
== Command ==
RUN: $PERL_EXE t/test/runtest.pl  2>&1
== Status ==
Status: 0
== Results ==
Hello world
== All ==
RUN: $PERL_EXE t/test/runtest.pl  2>&1
Hello world
Status: 0

__DATA__ test6
