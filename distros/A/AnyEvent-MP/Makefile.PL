use ExtUtils::MakeMaker;

use Canary::Stability AnyEvent::MP => 1, 5.008002;

my $mm = MM->new({
    dist         => {
       PREOP	=> 'pod2text MP.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
       COMPRESS	=> 'gzip -9v',
       SUFFIX	=> '.gz',
	            },
    NAME         => "AnyEvent::MP",
    VERSION_FROM => "MP/Config.pm",
    EXE_FILES    => ["bin/aemp"],
    CONFIGURE_REQUIRES => { ExtUtils::MakeMaker => 6.52, Canary::Stability => 0 },
    PREREQ_PM    => {
       AnyEvent           => 6.14,
       AnyEvent::Watchdog => 1.0,
       Digest::SHA3       => 0.24,
       Digest::HMAC       => 1.03,
       MIME::Base64       => 3,
       JSON::XS           => 2.25,
       CBOR::XS           => 1.5,
       Guard              => 1.022,
       common::sense      => 0,
       Task::Weaken       => 0,
    },
    META_MERGE => {
        recommends => {
           Net::Interface => 1.011,
        }
    },
});

$mm->flush;

