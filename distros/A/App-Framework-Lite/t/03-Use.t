#!/usr/bin/perl
#
use strict ;
use Test::More ;

use App::Framework::Lite ;

diag( "Testing auto-use of common modules" );

#
# Imported modules:
#
#	'Carp',
#	'Cwd',
#	'Getopt::Long qw(:config no_ignore_case)',
#	'Pod::Usage',
#	'File::Basename',
#	'File::Path',
#	'File::Temp',
#	'File::Spec',
#	'File::DosGlob qw(glob)',
#	'File::Which',

# -msg => $message_text ,
# -exitval => $exit_status

	my %tests = (
#	'Carp'											=> 'carp "this is ok"',
	'Cwd'											=> 'cwd()',
	'Getopt::Long qw(:config no_ignore_case)'		=> 'my $length; GetOptions("length=i" => \$length) ;',
	'Pod::Usage'									=> 'pod2usage(-msg => "a message", -exitval => "NOEXIT")',
	'File::Basename'								=> 'fileparse("/etc/tmp.pl", "\..*")',
	'File::Path'									=> 'mkpath("t")',
	'File::Temp'									=> 'my $tmp = tmpnam()',
	'File::Spec'									=> 'my $x=File::Spec->catfile("a", "b", "c");',
#	'File::DosGlob qw(glob)'						=> '',
#	'File::Which'									=> 'which("perl")',
	) ;

	plan tests => scalar(keys %tests) ;
	
	
	foreach my $test (sort keys %tests)
	{
		print "Testing $test ...\n" ;
		eval $tests{$test} ;
		if ($@)
		{
			fail("$test : $@") ;
		}
		else
		{
			pass("$test") ;
		}
	}

#	eval{
#		fileparse("/etc/tmp.pl", '\..*') ;
#	} ;
#	if ($@)
#	{
#		fail("fileparse : $@") ;
#	}
#	else
#	{
#		pass("fileparse") ;
#	}



#sub diag
#{
#	print "$_[0]\n" ;
#}	
#sub fail
#{
#	print "FAIL: $_[0]\n" ;
#}	
#sub pass
#{
#	print "PASS: $_[0]\n" ;
#}	
