use ExtUtils::MakeMaker;
use Config;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
	      'NAME'	     => 'Ace::Freesubs',
	      'VERSION_FROM' => 'Freesubs.pm', # finds $VERSION
	      'LIBS'         => ['-lc'],
	      'DEFINE'	     => '',
	      'OBJECT'       => '$(O_FILES)',
	      'XS'           => { 'Freesubs.xs'  => 'Freesubs.c' },
	      'XSPROTOARG'   => '-noprototypes',
);
