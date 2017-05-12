#
# $Id: Makefile.PL,v 0.1 2001/03/31 10:04:37 ram Exp $
#
#  Copyright (c) 2000-2001, Christophe Dehaudt & Raphael Manfredi
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: Makefile.PL,v $
# Revision 0.1  2001/03/31 10:04:37  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

use ExtUtils::MakeMaker;

print <<EOM if $] eq "5.006";

*************************************************
* Will raise a bug in Perl 5.6.0 -- see REAMDE  *
*************************************************

EOM

my %PL_FILES = map
	{ ($a = $_) =~ s/\.PL// ? ($_,$a) : () }
	glob('scripts/*.PL');

WriteMakefile(
    'NAME'	=> 'Carp::Datum',
    'VERSION_FROM' => 'Datum.pm', # finds $VERSION
	'PL_FILES'	=> \%PL_FILES,
	'EXE_FILES'	=> [ values %PL_FILES ],
	'PREREQ_PM' => {
		'Log::Agent'		=> '0.207',
		'Getargs::Long'		=> '0.103',
	},
    'LIBS'	=> [''],		# e.g., '-lm' 
    'DEFINE'	=> '',		# e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',			# e.g., '-I/usr/include/other' 
);

