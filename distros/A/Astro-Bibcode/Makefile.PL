
use strict;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile being created.
WriteMakefile(
        'NAME' => 'Astro::Bibcode',
        'VERSION_FROM' => 'Bibcode.pm',
	EXE_FILES => [ 'verifybib' ],
	($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	 (ABSTRACT_FROM => 'Bibcode.pm',
	  AUTHOR     => 'Tim Jenness <tjenness@cpan.org>') : ()),
        'dist'   => {COMPRESS=>'gzip -9f', SUFFIX=>'gz'},
);
