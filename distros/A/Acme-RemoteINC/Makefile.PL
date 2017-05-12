use ExtUtils::MakeMaker;
use 5.008;

WriteMakefile(
    NAME         => 'Acme::RemoteINC',
    VERSION_FROM => 'lib/Acme/RemoteINC.pm', # finds $VERSION
    AUTHOR       => 'William Hererra (whererra@skylightview.com)',
    ABSTRACT     => 'Slowest Possible Module Loading',
    LICENSE      => 'perl',    
    PREREQ_PM    => { Net::FTP => 0, File::Temp => 0, Test::Simple => 0 },
);
