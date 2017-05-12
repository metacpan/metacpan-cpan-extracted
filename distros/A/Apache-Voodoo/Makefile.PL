#!/usr/bin/perl

use 5.008000;
use ExtUtils::MakeMaker;

my %required_modules = (
	# voodoo-control uses CPAN under the hood to do some of it's work which is why it's listed here.
	'CPAN'                  => 1.9205,	
	'Apache::Session'       => 1.6,
	'Config::General'       => 2.27,
	'DBI'                   => 1.609,
	'Devel::StackTrace'     => 1.20,
	'Digest::MD5'           => 2.36,
	'Email::Valid'          => 0.15,
	'Exception::Class'      => 1.26,
	'Exception::Class::DBI' => 1.00,
	'File::Pid'             => 1.01,
	'HTML::Template'        => 2.7,
	'JSON::DWIW'            => 0.32,
	'Tie::Hash::Indexed'    => 0.05,    # Used by Table/Probe/MySQL.pm
	'Time::HiRes'           => 1.65,
	'XML::Checker'          => 0.13
);

my %optionals = (
	'Apache::Request'  => 1.33,
	'Apache::Cookie'   => 0,
	'Apache2::Request' => 2.08,
	'Apache2::Cookie'  => 2.08,

	'SOAP::Lite'            => 0.710,
	'Data::Structure::Util' => 0.15,

	'Pod::WSDL2'       => 0.06,	# prefer my forked version,
	'Pod::WSDL'        => 0.05,	# fallback to the main one if it's not installed

	'Log::Log4Perl'    => 1.24
);

eval {
	require "mod_perl2.pm";
};
if ($@) {
	eval {
		require "mod_perl.pm";
	};
}

print "mod_perl version: $mod_perl::VERSION\n";
if ($mod_perl::VERSION >= 1.99) {
	print "Adding prequisites for mod_perl Version 2 API...\n";
	add_mp2(\%required_modules);
}
elsif ($mod_perl::VERSION > 0) {
	print "Adding prequisites for mod_perl Version 1 API...\n";
	add_mp1(\%required_modules);
}
else {
	my $answer;
	print "\nCan't find mod_perl.pm or mod_perl2.pm, one of which is required.\n\n";
	while ($answer != /^[12]$/) {
		$answer = prompt("Do you want to use Apache 1.X or Apache 2.X? (1/2)",2);
		chomp($answer);
	}

	if ($answer == 1) {
		add_mp1(\%required_modules);
	}
	else {
		add_mp2(\%required_modules);
	}
}

eval { require SOAP::Transport::HTTP; };
if ($@) {
	print "\nApache::Voodoo can also optionally serve SOAP requests.\n";
	my $answer;
	while ($answer !~ /^[yn]/i) {
		$answer = prompt("Would you like me to add the dependencies to enable this feature? (y/n)",'y');
		chomp($answer);
	}

	if ($answer =~ /^y/i) {
		$required_modules{'SOAP::Lite'} = $optionals{'SOAP::Lite'};
		print "Adding prequisites for SOAP...\n";
	}
}
else {
	$required_modules{'SOAP::Lite'} = $optionals{'SOAP::Lite'};
}

if ($required_modules{'SOAP::Lite'}) {
	$required_modules{'Data::Structure::Util'} = $optionals{'Data::Structure::Util'};

	eval { require Pod::WSDL2; };
	if ($@) {
		$required_modules{'Pod::WSDL'}  = $optionals{'Pod::WSDL'};
	}
	else {
		print "Pod::WSDL2 found\n";
		$required_modules{'Pod::WSDL2'}  = $optionals{'Pod::WSDL2'};
	}
}

if (defined($required_modules{'Pod::WSDL'})) {
	# check to see if we have my version of Pod::WSDL installed
	eval {
		require Pod::WSDL2;
	};
	if (!$@) {
		# they do, remove this dependancy
		delete $required_modules{'Pod::WSDL'};
	}
}

eval { require Log::Log4perl; };
if ($@) {
	print "\nApache::Voodoo can log debugging message with Log4perl.\n";
	my $answer;
	while ($answer !~ /^[yn]/i) {
		$answer = prompt("Would you like me to add the dependencies to enable this feature? (y/n)",'y');
		chomp($answer);
	}

	if ($answer =~ /^y/i) {
		$required_modules{'Log::Log4perl'} = $optionals{'Log::Log4perl'};
		print "Adding prequisites for Log4perl...\n";
	}
}
else {
	$required_modules{'Log::Log4perl'} = $optionals{'Log::Log4perl'};
}


WriteMakefile(
	NAME          => 'Apache::Voodoo',
	VERSION_FROM  => 'lib/Apache/Voodoo.pm',
	PREREQ_PM     => \%required_modules,
	(
		$] >= 5.008 ?
		(ABSTRACT_FROM => 'lib/Apache/Voodoo.pod', # retrieve abstract from module
		AUTHOR         => 'Maverick Edwards <maverick@smurfbane.org>') : ()
	),
	INSTALLSCRIPT => $paths{'SBINDIR'},
	EXE_FILES => ['bin/voodoo-control']
	# PM_FILTER => $filter
);


sub add_mp1 {
	$req = shift;
	$req->{Apache::Request} = $optionals{Apache::Request};
	$req->{Apache::Cookie}  = $optionals{Apache::Cookie};
}

sub add_mp2 {
	$req = shift;
	$req->{Apache2::Request} = $optionals{Apache2::Request};
	$req->{Apache2::Cookie}  = $optionals{Apache2::Cookie};
}

################################################################################
# Copyright (c) 2005 Steven Edwards.  All rights reserved.
################################################################################
