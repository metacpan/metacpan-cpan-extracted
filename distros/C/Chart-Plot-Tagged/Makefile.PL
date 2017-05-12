use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Chart::Plot::Tagged',
    VERSION_FROM      => 'lib/Chart/Plot/Tagged.pm', # finds $VERSION
    ABSTRACT          => 'Plot with tags',
    PREREQ_PM         => {
                        'Chart::Plot'   => 0.11,
    },
    AUTHOR            => "Francois PERRAD (francois.perrad\@gadz.org)",
);
