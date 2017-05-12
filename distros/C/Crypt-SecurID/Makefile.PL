#
# Makefile.PL - MakeMaker source for SecurID perl module
#
# $Id: Makefile.PL,v 1.4 2003/08/06 20:48:07 pliam Exp $
#

use ExtUtils::MakeMaker;

# latest makemaker doesn't know to automatically link with g++
# process otherwise command line 'LD=g++' (might have to comment this out)
push(@ARGV, 'LD=g++');

WriteMakefile(
	NAME => 'Crypt::securid',
	VERSION_FROM => 'SecurID.pm',
	'PREREQ_PM' => { 'Test::More' => 0.01 },
	OBJECT => 'sid.o securid.o securid_wrap.o'
);
