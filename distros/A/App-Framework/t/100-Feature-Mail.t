#!/usr/bin/perl
#
use strict ;
use Test::More ;

use App::Framework '+Mail' ;
use config ;

# VERSION
our $VERSION = '1.000' ;

my %set = (
	'from'			=> 'someone@domain.co.uk',
	'to'			=> 'a@domain.co.uk, b@domain.co.uk, c@domain.co.uk',
	'error_to'		=> 'd@domain.co.uk',
	'err_level'		=> 'error',
	'subject'		=> 'a test',
	'host'			=> 'localhost',
) ;

my %man = (
	'-mail-from'			=> 'someone@domain.co.uk',
	'-mail-to'			=> 'a@domain.co.uk, b@domain.co.uk, c@domain.co.uk',
	'-mail-error-to'		=> 'd@domain.co.uk',
	'-mail-err-level'		=> 'error',
	'-mail-subject'		=> 'a test',
	'-mail-host'			=> 'localhost',
) ;

my %tests = (
	'set'	=> scalar(keys %set),
	'man'	=> scalar(keys %man),
) ;


	diag( "Testing Mail feature" );

	if (!exists($config::TO_TEST{'App::Framework::Feature::Mail'}))
	{
	    plan skip_all => 'Module not selected for full install';
		exit 0 ;
	}


	eval {
		require Net::SMTP;
	} ;
	if ($@)
	{
	    plan skip_all => 'Unable to run tests since Net::SMTP not available';
		exit 0 ;
  	}

	my $stdout="" ;
	my $stderr="" ;


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
		$tests{'man'} = 0 ;
	}

	## Planned tests
	my $test_count = 0 ;
	foreach my $test (keys %tests)
	{
		$test_count += $tests{$test} ;
	}
	plan tests => $test_count ;
	
	## MAN pages
	if ($tests{'man'})
	{
		eval{
			local *STDOUT ;
			local *STDERR ;
	
			open(STDOUT, '>', \$stdout)  or die "Can't open STDOUT: $!" ;
			open(STDERR, '>', \$stderr) or die "Can't open STDERR: $!";
	
			@ARGV = ('-help') ;	
			App::Framework->new('exit_type'=>'die')->go() ;
		} ;

		foreach my $test (keys %man)
		{
			like  ($stdout, qr/$test/im, "Man page entry existance: $test");
		}

	}

	# Create application and run it
	@ARGV = () ;	
	go() ;




#=================================================================================
# SUBROUTINES EXECUTED BY APP
#=================================================================================

#----------------------------------------------------------------------
# Main execution
#
sub app
{
	my ($app, $opts_href) = @_ ;

	if ($tests{'set'})
	{
		foreach my $field (keys %set)
		{
			$app->Mail()->set(
				$field		=> $set{$field},
			) ;
	
			my $value = $app->Mail()->$field() ;
			is($value, $set{$field}, "Checking field $field") ;	
		}
	}
	
}

#----------------------------------------------------------
sub check
{
}




#=================================================================================
# SETUP
#=================================================================================

__DATA__

[SUMMARY]
Tests the application object with Mail feature

