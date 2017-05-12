use ExtUtils::MakeMaker;

my $mm = MM->new({
    dist         => {
       PREOP	=> 'pod2text Watchdog.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
       COMPRESS	=> 'gzip -9v',
       SUFFIX	=> '.gz',
	            },
    NAME         => "AnyEvent::Watchdog",
    VERSION_FROM => "Watchdog.pm",
    PREREQ_PM    => {
       common::sense => 0,
       AnyEvent      => 4.15,
    },
});

$mm->flush;

