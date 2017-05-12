use strict;
use ExtUtils::MakeMaker;
use File::Spec;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile being created.
WriteMakefile(
        'NAME' => 'Astro::Correlate',
        'VERSION_FROM' => 'Correlate.pm',
        'PREREQ_PM' => {
                        'Astro::Catalog' => 0,
                        'File::SearchPath' => 0,
                       },
        ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
         (ABSTRACT_FROM => 'Correlate.pm',
          AUTHOR     => 'Brad Cavanagh <brad.cavanagh@gmail.com>') : ()),
        'dist'   => {COMPRESS=>'gzip -9f', SUFFIX=>'gz'},
);
