use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'CGI::CIPP',
    'VERSION_FROM' => 'CIPP.pm', # finds $VERSION
    'PREREQ_PM' => {
                'CIPP' => 2.13
                },
    'dist' => {
        COMPRESS => "gzip",
        SUFFIX => "gz"
    }
);
