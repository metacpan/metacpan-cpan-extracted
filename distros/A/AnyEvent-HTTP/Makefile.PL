use ExtUtils::MakeMaker;

my $mm = MM->new({
    dist         => {
       PREOP	=> 'pod2text HTTP.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
       COMPRESS	=> 'gzip -9v',
       SUFFIX	=> '.gz',
	            },
    NAME         => "AnyEvent::HTTP",
    VERSION_FROM => "HTTP.pm",
    PREREQ_PM    => {
       AnyEvent      => 5.33,
       common::sense => 3.3,
    },
    META_MERGE   => {
       recommends => {
          URI => 0,
       },
    },
});

$mm->flush;

