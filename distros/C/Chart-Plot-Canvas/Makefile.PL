use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'Chart::Plot::Canvas',
    'VERSION_FROM'  => 'lib/Chart/Plot/Canvas.pm',
    'ABSTRACT'      => 'Plot two dimensional data in an Tk Canvas',
    'PREREQ_PM'     => {
                        'Tk'                    => 0,
                        'Chart::Plot'           => 0.11,
                        'Chart::Plot::Tagged'   => 0.02,
    },
    'AUTHOR'        => "Francois PERRAD (francois.perrad\@gadz.org)",
    'dist'          => {
                        'COMPRESS'      => 'gzip',
                        'SUFFIX'        => '.gz',
    },
);

