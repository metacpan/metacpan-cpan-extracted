use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

use Apache::src ();

WriteMakefile(
    'NAME'	=> 'Apache::LogFile',
    'VERSION_FROM' => 'LogFile.pm', # finds $VERSION
    'INC'	=> Apache::src->new->inc,
    'dist'    => {
        PREOP => 'pod2text LogFile.pm > README',
	COMPRESS=> 'gzip -9f', SUFFIX=>'gz',
    },
    'macro' => {
        CVSROOT => 'www.modperl.com:/local/cvs_repository',
    },
);

sub MY::postamble {

    return <<'EOF';
cvs_export :
	cvs -d $(CVSROOT) export -rv$(VERSION_SYM) -d$(DISTVNAME) .

cvs_rtag :
	cvs -d $(CVSROOT) rtag v$(VERSION_SYM) Apache-LogFile

EOF
}
