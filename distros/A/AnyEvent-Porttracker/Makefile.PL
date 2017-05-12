use ExtUtils::MakeMaker;

my $mm = MM->new({
    dist         => {
       PREOP	=> 'pod2text Porttracker.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
       COMPRESS	=> 'gzip -9v',
       SUFFIX	=> '.gz',
	            },
    NAME         => "AnyEvent::Porttracker",
    VERSION_FROM => "Porttracker.pm",
    PREREQ_PM    => {
       common::sense    => 3.3,
       AnyEvent         => 5,
       Digest::HMAC_MD6 => 0.01,
       JSON             => 2,
       MIME::Base64     => 3.08,
    },
});

$mm->flush;

