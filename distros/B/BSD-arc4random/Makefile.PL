# $MirOS: contrib/hosted/tg/code/BSD::arc4random/Makefile.PL,v 1.6 2011/06/05 22:59:04 tg Exp $
#-
# Copyright (c) 2008, 2009, 2011
#	Thorsten Glaser <tg@mirbsd.org>
#
# Provided that these terms and disclaimer and all copyright notices
# are retained or reproduced in an accompanying document, permission
# is granted to deal in this work without restriction, including un-
# limited rights to use, publicly perform, distribute, sell, modify,
# merge, give away, or sublicence.
#
# This work is provided "AS IS" and WITHOUT WARRANTY of any kind, to
# the utmost extent permitted by applicable law, neither express nor
# implied; without malicious intent or gross negligence. In no event
# may a licensor, author or contributor be held liable for indirect,
# direct, other damage, loss, or other issues arising in any way out
# of dealing in the work, even if advised of the possibility of such
# damage or existence of a defect, except proven that it results out
# of said person's immediate fault when using the work as intended.

use 5.000;
use ExtUtils::MakeMaker;

# configuration, set to auto or manual
my $cfg = 'auto';
# override these values if manual mode
my $libs = '';
my $defs = '-DHAVE_ARC4RANDOM_PUSHB=1';
my $incs = '';
my $objs = '';
# do not override below for auto mode
if ($cfg eq 'auto') {
	# note order is important
	if ($^O ne 'mirbsd' && $^O ne 'cygwin') {
		$defs = '-DHAVE_ARC4RANDOM_PUSHB=0';
	}
	if ($^O eq 'interix') {
		$libs = '-lcrypt';
	}
	if (($^O eq 'gnu') ||
	    ($^O eq 'gnukfreebsd') ||
	    ($^O eq 'linux')) {
		# Debian GNU/HURD, GNU/kFreeBSD, GNU/Linux
		# either use libbsd (lenny and up):
		#$incs = '-include /usr/include/bsd/bsd.h';
		#$libs = '-lbsd';
		# or use the contributed arc4random.c file
		$objs = 'arc4random.o';
		$defs .= ' -DHAVE_SYS_SYSCTL_H=0 -DHAVE_STDINT_H=1';
		$defs .= ' -DNEED_ARC4RANDOM_DECL';
	}
	if (($^O eq 'cygwin') || ($^O eq 'MSWin32') ||
	    ($^O eq 'irix') ||
	    ($^O eq 'solaris')) {
		# Cygwin, Solaris: use arc4random.c contributed file
		# IRIX: the same, except we don't know if it works there
		# XXX the presence of arc4random.c here is a KLUDGE going away!
		# XXX Solaris 10 has <stdint.h> but Cygwin and Solaris 8 don't.
		$objs = 'arc4random.o';
		$defs .= ' -DNEED_ARC4RANDOM_DECL';
		if ($^O eq 'solaris') {
			$defs .= ' -DHAVE_SYS_SYSCTL_H=0 -DHAVE_STDINT_H=0';
			$defs .= ' -DUSE_INTTYPES -DREDEF_USCORETYPES';
		}
	}
}

if ($objs eq '') {
	$objs = 'arc4rnd_xs.o';
} else {
	$objs = 'arc4rnd_xs.o ' . $objs;
}

WriteMakefile(
	NAME			=> 'BSD::arc4random',
	VERSION_FROM		=> 'lib/BSD/arc4random.pm',
	PREREQ_PM		=> {},
	($] >= 5.005 ? (
	    ABSTRACT_FROM	=> 'lib/BSD/arc4random.pm',
	    AUTHOR		=> 'Thorsten Glaser <tg@mirbsd.org>'
	) : ()),
	LIBS			=> $libs,
	DEFINE			=> $defs,
	INC			=> $incs,
	OBJECT			=> $objs
);
