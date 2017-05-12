#
# $Id: Makefile.PL,v 1.1.1.1 2001/06/17 01:37:51 ptimof Exp $
#

use ExtUtils::MakeMaker;
use strict;

use vars qw($CC);

$CC = $ENV{CC} || 'cc';

unlink 'conftest';
if (system($CC, 't/conftest.c', '-o', 'conftest', '-lm', '-lmad',
	'-lmp3lame') != 0) {
	print <<"EOF";

You may not have installed the LAME or MAD libraries and header files,
or your compiler installation is flawed. Please review the error
messages from the compiler above.

You can change the default compiler by setting the \$CC environment
variable in your shell.
EOF
	exit 1;
}
unlink 'conftest';

WriteMakefile(
	NAME				=> 'Audio::MPEG',
	VERSION_FROM		=> 'MPEG.pm',
	($] >= 5.005 ?
	(ABSTRACT_FROM		=> 'MPEG.pm',
	AUTHOR				=> 'Peter Timofejew <peter@timofejew.com>') : ()),
	OPTIMIZE			=> '-O2',
	MYEXTLIB			=> 'libmpeg$(LIB_EXT)',
	LIBS				=> ['-lm -lmad -lmp3lame'],
	clean				=> { FILES => 'conftest' },
);

sub MY::postamble { '
$(MYEXTLIB): $(MYEXTLIB)($(O_FILES))
	$(AR) cr $@ $?
	$(RANLIB) $@
';
}
