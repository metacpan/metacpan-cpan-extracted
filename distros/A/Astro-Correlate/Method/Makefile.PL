use strict;
use ExtUtils::MakeMaker;
use File::Spec;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile being created.
WriteMakefile(
        'NAME' => 'Astro::Correlate::Method::XXX',
	'DISTNAME' => 'Astro-Correlate-Method',
	'VERSION' => '0.01',
        'PREREQ_PM' => {
                        'Astro::Catalog' => 0,
                       },
        ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
         (ABSTRACT => 'Pluggable correlation methods',
          AUTHOR     => 'Brad Cavanagh <b.cavanagh@jach.hawaii.edu>') : ()),
        'dist'   => {COMPRESS=>'gzip -9f', SUFFIX=>'gz'},
);
