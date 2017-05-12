#!/usr/bin/perl
#
use strict ;

$|++ ; # ensure each line is output individually


	my $mode = $ARGV[0] || 'hello' ;
	my $sleep = $ARGV[1] || 10 ;
	
	if ($mode eq 'ping')
	{
		my @data = (
			'Some output',
			'Some more output',
			'',
			'RESULTS: 10 / 10 passed!',
		) ;
		foreach (@data)
		{
			print "$_\n" ;
			sleep($sleep) ;
		}
	}
	else
	{
		print "Hello world\n" ;
	}
