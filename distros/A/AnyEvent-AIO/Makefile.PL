use ExtUtils::MakeMaker;

my $mm = MM->new({
    dist         => {
       PREOP	=> 'pod2text AIO.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
       COMPRESS	=> 'gzip -9v',
       SUFFIX	=> '.gz',
	            },
    NAME         => "AnyEvent::AIO",
    VERSION_FROM => "AIO.pm",
    PREREQ_PM    => {
       IO::AIO   => 3.0,
       AnyEvent  => 3.4,
    },
});

$mm->flush;

