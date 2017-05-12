#
# Makefile.PL - distribution MakeMaker script
#
# $Id: Makefile.PL,v 1.8 2002/05/19 05:15:26 pliam Exp $
#

use ExtUtils::MakeMaker;

#
# write makefile
#
WriteMakefile(
    'NAME' => 'Apache::SecSess',
	'VERSION_FROM' => 'SecSess.pm',
	'PREREQ_PM' => { 
		'Crypt::Rijndael' => 0.04,
		'Digest::MD5' => 0,
		'MIME::Base64' => 0,
		'IO::File' => 0,
		'DBI' => 0,
		'DBD::Pg' => 0
	}
);


#
# add demo target
#
sub MY::postamble {
return <<'ENDTARGET';
install_demo:
	(cd demo; make install)
	(cd utils; make; make install; make install-key)
ENDTARGET
}
