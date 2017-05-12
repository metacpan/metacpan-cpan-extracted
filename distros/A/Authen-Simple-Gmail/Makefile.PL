use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Authen::Simple::Gmail',
    AUTHOR        => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    VERSION_FROM  => 'lib/Authen/Simple/Gmail.pm',
    ABSTRACT_FROM => 'lib/Authen/Simple/Gmail.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'  => 0,
        'Net::Detect' => 0,
        'File::Slurp' => 0,

        'IO::Socket::SSL'         => 0,
        'Authen::Simple::Adapter' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Authen-Simple-Gmail-*' },
);
