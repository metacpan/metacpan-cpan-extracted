use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'AnyEvent::XMPP',
    AUTHOR              => 'Robin Redeker <elmex@ta-sa.org>',
    LICENSE             => 'perl',
    VERSION_FROM        => 'lib/AnyEvent/XMPP.pm',
    ABSTRACT_FROM       => 'lib/AnyEvent/XMPP.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'AnyEvent'           => 0,
        'AnyEvent::Socket'   => 0,
        'AnyEvent::Handle'   => 0,
        'Scalar::Util'       => 0,
        'XML::Writer'        => 0,
        'XML::Parser::Expat' => 0,
        'MIME::Base64'       => 0,
        'Net::LibIDN'        => 0,
        'Authen::SASL'       => 0,
        'Time::Local'        => 0,
        'Object::Event'      => 0.7,
        # We depend on the same version that AnyEvent recommends.
        # While it does make sense for AnyEvent to not require SSL, it is very
        # very odd to use XMPP without SSL.
        # This should prevent issues like RT#80148
        'Net::SSLeay'        => 1.33,
    },
    dist                => {
       COMPRESS => 'gzip -9f',
       SUFFIX => 'gz',
       PREOP => 'pod2text lib/AnyEvent/XMPP.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
    },
    clean               => { FILES => 'AnyEvent-XMPP-*' },
    META_MERGE          => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'git://github.com/AnyEvent-XMPP/AnyEvent-XMPP.git',
                web  => 'https://github.com/AnyEvent-XMPP/AnyEvent-XMPP',
            },
        },
    },
);
