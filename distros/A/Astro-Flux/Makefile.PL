
use strict;
use ExtUtils::MakeMaker;
use File::Spec;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile being created.
WriteMakefile(
        'NAME' => 'Astro::Flux',
        'VERSION_FROM' => 'Flux.pm',
        'PREREQ_PM' => {
                        'Astro::WaveBand' => 0,
                        'DateTime' => 0,
                        'Misc::Quality' => 0,
                        'Number::Uncertainty' => 0,
		       },
	($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	 (ABSTRACT_FROM => 'Flux.pm',
	  AUTHOR     => 'Brad Cavanagh <b.cavanagh@jach.hawaii.edu>') : ()),
        'dist'   => {COMPRESS=>'gzip -9f', SUFFIX=>'gz'},
);
