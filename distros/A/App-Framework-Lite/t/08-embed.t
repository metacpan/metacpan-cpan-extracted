#!/usr/bin/perl
#
use strict ;
use File::Basename;

use Test::More;

my $DEBUG=0;

	my $stdout="" ;
	my $stderr="" ;

	diag( "Testing module embed" );
	
	my $embedded_script = "./t/embed.pl" ;
	unlink $embedded_script ;

	my @run_args = (
		['run',		''],
		['help',	'-help'],
		['man',		'-man'],
	) ;	
	my @embed_args = (
		['all',		''],
#		['no-lib',	'-alf-embed-lib 0'],
		['no-comp',	'-alf-compress 0'],
#		['neither',	'-alf-embed-lib 0 -alf-compress 0'],
	) ;	
	my @tests = (
		't/embed/test1.pl',
		't/embed/test2.pl',
		't/embed/test3.pl',
	) ;
	plan tests => (scalar(@embed_args)) * (scalar(@tests)) * (scalar(@run_args)) ;

	my %expected ;
	foreach my $test_script (@tests)
	{
		## get "golden" output
		foreach my $run_aref (@run_args)
		{
			my ($name, $arg) = @$run_aref ;
			my $result = run_script($test_script, $arg) ;
			$expected{$name} = $result ;
print "$name =>\n$result\n\n" ;
		}
		
		## embed with different options
		foreach my $embed_aref (@embed_args)
		{
			## create embedded version
			my ($embed, $arg) = @$embed_aref ;
			$arg .= "  -alf-embed $embedded_script" ;
			run_script($test_script, $arg) ;
			
			## Run tests
			foreach my $run_aref (@run_args)
			{
				my ($name, $arg) = @$run_aref ;
				my $result = run_embedded($embedded_script, $arg) ;

				# convert script name to match golden
				my $progname = (fileparse($test_script, '\..*'))[0] ;
				my $embedname = (fileparse($embedded_script, '\..*'))[0] ;
				$result =~ s/$embedname/$progname/g ;
				
				is($expected{$name}, $result, "Embedded script with $embed options, run with $name options") ;
			}
		}
	}

	unlink $embedded_script ;



#=================================================================================
# SUBROUTINES
#=================================================================================

sub run_script
{
	my ($script, $args) = @_ ;

	my $results ;
	eval {
	$results = `$^X -Mblib $script $args 2>&1` ;
	} ;
	return $results ;
}

sub run_embedded
{
	my ($script, $args) = @_ ;

	my $results ;
	eval {
	$results = `$^X $script $args 2>&1` ;
	} ;
	return $results ;
}


