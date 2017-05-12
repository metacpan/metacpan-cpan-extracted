use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Apache::AuthenURL',
    VERSION_FROM  => 'lib/Apache/AuthenURL.pm',
    PREREQ_PM => { LWP::UserAgent => '0' } 
);
