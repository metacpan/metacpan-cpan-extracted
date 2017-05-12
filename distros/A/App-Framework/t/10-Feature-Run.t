#!/usr/bin/perl
#
use strict ;
use Test::More ;
use File::Which ;

use App::Framework ':Script +Run' ;

# VERSION
our $VERSION = '1.003' ;

my @data = (
	'Some output',
	'Some more output',
	'',
	'RESULTS: 10 / 10 passed!',
) ;

my %progs = (
	'not-there' => 1, 
	'ls' => 1, 
	'dir' => 1,
) ;

my @expected_array = (
	{
		expected 	=> "Hello world",
		delay 		=> 0,
		args		=> [
			'cmd'		=> "$^X t/test/runtest.pl", 
			'progress'	=> \&progress,
		]
	},
	{
		expected 	=> "Hello world",
		delay 		=> 0,
		args		=> [
			"$^X t/test/runtest.pl", 
		]
	},
	{
		expected 	=> "Hello world",
		delay 		=> 0,
		args		=> [
			"$^X", "t/test/runtest.pl", 
		]
	},
	
	# early timeout test
	{
		expected 	=> "Hello world",
		delay 		=> 0,
		args		=> [
			'cmd'		=> "$^X t/test/runtest.pl", 
			'progress'	=> \&progress,
			'timeout'	=> 60,
		]
	},
	
	{
		expected 	=> \@data,
		delay 		=> 1,
		args		=> [
			'cmd'		=> "$^X t/test/runtest.pl", 
			'progress'	=> \&progress,
			'args'		=> "ping 1",
			'timeout'	=> 5,
		]
	},
#	{
#		expected 	=> \@data,
#		delay 		=> 5,
#		args		=> [
#			'cmd'		=> "$^X t/test/runtest.pl", 
#			'progress'	=> \&progress,
#			'args'		=> "ping 5",
#			'timeout'	=> 25,
#		]
#	},

) ;


my $data_tests = 0 ;
my $no_data_tests = 0 ;
my $progress_tests = 0 ;
foreach my $test_href (@expected_array)
{
	## progress checked
	my $prog ;
	foreach (@{$test_href->{args}})
	{
		if ($_ eq 'progress')
		{
			++$prog ;
			last ;
		}
	}
	if ($prog)
	{
		++$progress_tests  ;

		if (ref($test_href->{expected}) eq 'ARRAY')
		{
			++$data_tests  ;
		}
		else
		{
			++$no_data_tests ;		
		}
	}

}


print "Data tests=$data_tests, No data tests=$no_data_tests\n" ;

# feature/direct 2 x {
#   no data tests -> 1 test per
#   data tests -> 1 test per data line
#   tests -> 1 test per test
# }
# 3 object tests
# progs test
plan tests => $no_data_tests * 1 * 2
	+ $data_tests * scalar(@data) * 2
	+ scalar(@expected_array) * 2
	+ 3 
	+ 1 + 1 + scalar(keys %progs) ;


	my $expected ;
	my $delay ;

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


	my $run1 = $app->feature("run") ;
	my $class1 = ref($run1) ;
	
	is($class1, 'App::Framework::Feature::Run', 'Run feature class check') ;
	
	my $run = $app->run ;
	my $class = ref($run) ;
	is($run, $run1, 'Run object check') ;

	my $run2 = $app->Run ;
	is($run, $run2, 'Run object check (access alias)') ;

	is($run->on_error, 'fatal', 'Default on_error setting') ;


	$run->on_error('fatal') ;
	eval{$run->required({ %progs }) ;} ;
	ok ($@, "Expected failure to find non-existent program") ;

	$run->on_error('status') ;
	my $required = $run->required({ %progs }) ;
$app->prt_data("Required stats=", $required) ;	
	foreach my $exe (keys %progs)
	{
		if ($exe eq 'not-there')
		{
			is($required->{$exe}, undef, "$exe status") ;
		}
		else
		{
			## if we can find it then the framework should find it
			if (which($exe))
			{
				ok ($required->{$exe}, "Expected to find $exe") ;
			}
			else
			{
				is($required->{$exe}, undef, "Expected not to find $exe") ;
			}
		}
	}	

	my $idx = 1 ;
	foreach my $test_href (@expected_array)
	{
$app->prt_data("Test HASH=", $test_href) ;
		$expected = $test_href->{expected} ;
		$delay = $test_href->{delay} ;
		my $results_aref ;
		
		## feature run
		$app->run( @{$test_href->{args}} ) ;

		# results
		$results_aref = $app->run->results() ;
		if (ref($test_href->{expected}) eq 'ARRAY')
		{
			is_deeply($results_aref, $test_href->{expected}, "$idx : Test array results") ;
		}
		else
		{
			is($results_aref->[0], $test_href->{expected}, "$idx : Test scalar results") ;
		}
		
		## direct object access
		$run->run( @{$test_href->{args}} ) ;
		
		# results
		$results_aref = $run->results() ;
		if (ref($test_href->{expected}) eq 'ARRAY')
		{
			is_deeply($results_aref, $test_href->{expected}, "$idx : Test direct array results") ;
		}
		else
		{
			is($results_aref->[0], $test_href->{expected}, "$idx : Test direct scalar results") ;
		}
		
		++$idx ;
	}

	
}

#=================================================================================
# SUBROUTINES
#=================================================================================

#---------------------------------------------------------------------------------
sub progress
{
	my ($line, $linenum, $state_href) = @_ ;
	print "progress (line num=$linenum): $line\n" ;
$app->prt_data("Expected=", $expected, "\n") ;
	
	if (ref($expected) eq 'ARRAY')
	{
		is($line, $expected->[$linenum-1], "Progress line compare: $line") ;
		if ($linenum==1)
		{
#			ok(1) ; #dummy
			$state_href->{then} = time ;
		}
		else
		{
			my $now = time ;
			my $dly = $now - $state_href->{then} ; 
			my $tol = $delay / 2 ;
			$tol ||= 1 ;
			# don't check timing - isn't accurate on some OSs and doesn't actually matter anyway!
#			ok( ($dly > $delay-$tol) && ($dly < $delay+$tol), "Output timing check") ; 
			$state_href->{then} = $now ;
		}
	}
	else
	{
		is($line, $expected, "Progress line compare: $line") ;
	}
}


#=================================================================================
# SETUP
#=================================================================================
__DATA__

[SUMMARY]

Tests run feature


