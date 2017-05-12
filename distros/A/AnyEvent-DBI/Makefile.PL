use ExtUtils::MakeMaker;

my $mm = MM->new({
    dist         => {
       PREOP	=> 'pod2text DBI.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
       COMPRESS	=> 'gzip -9v',
       SUFFIX	=> '.gz',
	            },
    NAME         => "AnyEvent::DBI",
    VERSION_FROM => "DBI.pm",
    PREREQ_PM        => {
       AnyEvent      => 4.15,
       DBI           => 1.0,
       common::sense => 3.3,
    },
});

$mm->flush;

