use ExtUtils::MakeMaker;

WriteMakefile(
    NAME           => 'Authen::SASL::Authd',
    AUTHOR         => 'Alex Protasenko <aprotasenko@bkmks.com>',
    VERSION_FROM   => 'lib/Authen/SASL/Authd.pm',
    ABSTRACT_FROM  => 'lib/Authen/SASL/Authd.pm',
    PREREQ_PM      => { },
    dist           => {
        PREOP => 'pod2text lib/Authen/SASL/Authd.pm | tee README >$(DISTVNAME)/README', },
);

