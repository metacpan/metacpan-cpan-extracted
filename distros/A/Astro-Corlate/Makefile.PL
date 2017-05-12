use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
               'NAME'           => 'Astro::Corlate',
               'VERSION'        => '2.0',
               'PREREQ_PM'      => { },
               'dist'           => { COMPRESS => "gzip -9f"},
               ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
               ( ABSTRACT       => 'Module used to wrap ARK Corlate',
                 AUTHOR         => 'Alasdair Allan <aa@astro.ex.ac.uk>') : ()),

);
