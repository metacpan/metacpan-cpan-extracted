use ExtUtils::MakeMaker;

use 5.008002;

my $mm = MM->new({
    dist         => {
       PREOP	=> 'pod2text MP.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
       COMPRESS	=> 'gzip -9v',
       SUFFIX	=> '.gz',
	            },
    NAME         => "Coro::MP",
    VERSION_FROM => "MP.pm",
    PREREQ_PM    => {
       Coro               => 5.2,
       AnyEvent           => 5.11,
       AnyEvent::MP       => 1.21,
       common::sense      => 0,
    },
});

$mm->flush;

