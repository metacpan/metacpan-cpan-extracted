use ExtUtils::MakeMaker;

my $mm = MM->new({
    dist         => {
       PREOP	=> 'pod2text MPV.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
       COMPRESS	=> 'gzip -9v',
       SUFFIX	=> '.gz',
	            },
    NAME         => "AnyEvent::MPV",
    VERSION_FROM => "MPV.pm",
    META_MERGE   => {
       recommends => {
          JSON::XS => 3,
       },
    },
    PREREQ_PM    => {
       Task::Weaken  => 1,
       common::sense => 3.2,
       JSON::PP      => 2.0,
       AnyEvent      => 5.0,
    },
});

$mm->flush;

