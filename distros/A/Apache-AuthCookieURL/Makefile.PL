use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME            => 'Apache::AuthCookieURL',
    VERSION_FROM    => 'AuthCookieURL.pm', # finds $VERSION
    PREREQ_PM       => {
        Apache::Cookie  => 0,
        Apache::URI     => 0,
    },
    
    NORECURS        => 1,
    DIR             => [],

    dist => {
        COMPRESS    => 'gzip',
        SUFFIX      => 'gz',
    },
);



