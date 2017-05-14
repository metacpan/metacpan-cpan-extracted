#!/usr/bin/perl

use ExtUtils::MakeMaker;

##
# MakeMaker script for Agent.pm
# This script checks module dependancies, and generates a Makefile.
# --Steve Purkis <spurkis@engsoc.carleton.ca>, September 7, 1998.
##


##
# Variables

my $pkg = 'Agent';				# module package name
my %modules = (					# [required] modules
	'IO::Socket' => 'required',
	'Class::Tom' => 'required',
	'Data::Dumper' => 'required',
	'Thread'     => ''
);


##
# Program

select(STDERR);
$| = 1;

print "Configuring Agent for $^O...\n";
if ($^O =~ /win32/i) {
	print "If you don't have a make utility, see the INSTALL file.\n";
}
checkmod( @required );
WriteMakefile(
	'NAME'	=> 'Agent',
	'VERSION_FROM' => 'Agent.pm'
);

print <<DONE;
Done.

Please report any bugs to perl5-agents\@daft.com
To finish installing Agent you should run:

	make
	make test
	make install

DONE


sub checkmod {
	print "\nChecking module dependancies:\n";
	my @modules = keys(%modules);
	my $failed;

	foreach $mod (@modules) {
		print "\t$mod..... ";
		eval " use $mod; ";
		if ($@) {
			print "not ";
			$missing{$mod} = 1;
			$failed += 1 if ($modules{$mod});
		}
		print "found.\n";
	}
	if (%missing) {
		print "\nI can't find the following modules on your system:\n";
		foreach (keys(%missing)) {
			($modules{$_})
			   ? print "\t$_ *\n"
			   : print "\t$_\n";
		}
		if ($failed) {
			print <<DONE;

Required modules are indicated with an '*'.  You should make sure they are
installed on your system and run this script again.

Press <enter>...
DONE
			my $dummy = <STDIN>;
			exit 1;
		} else {
			print <<DONE2;

That's ok, though.  I don't _really_ need them.  But to get the most out of
this package, you should really install them.

DONE2
		}
	} else { print "You seem to have all the required modules.\n"; }
}

