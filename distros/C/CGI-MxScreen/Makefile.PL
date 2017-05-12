#
# $Id: Makefile.PL,v 0.1 2001/04/22 17:57:03 ram Exp $
#
#  Copyright (c) 1998-2001, Raphael Manfredi
#  Copyright (c) 2000-2001, Christophe Dehaudt
#  
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#
# HISTORY
# $Log: Makefile.PL,v $
# Revision 0.1  2001/04/22 17:57:03  ram
# Baseline for first Alpha release.
#
# $EndLog$
#

use ExtUtils::MakeMaker;
eval q(use Carp::Datum::MakeMaker;);

WriteMakefile(
    'NAME'	=> 'CGI::MxScreen',
    'VERSION_FROM' => 'MxScreen.pm', # finds $VERSION
	'PREREQ_PM' => {
		'CGI::Test'				=> '0.103',
		'Carp::Datum'			=> '0',
		'Crypt::Blowfish'		=> '0',
		'Crypt::CBC'			=> '1.22',
		'Digest::MD5'			=> '0',
		'Getargs::Long'			=> '0.103',
		'LockFile::Simple'		=> '0.205',
		'Log::Agent'			=> '0.208',
		'Log::Agent::Logger'	=> '0.101',
		'Log::Agent::Rotate'	=> '0.103',
		'Storable'				=> '1.011',
		'Time::HiRes'			=> '0',
	},
    'LIBS'	=> [''],		# e.g., '-lm' 
    'DEFINE'	=> '',		# e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',			# e.g., '-I/usr/include/other' 
);

