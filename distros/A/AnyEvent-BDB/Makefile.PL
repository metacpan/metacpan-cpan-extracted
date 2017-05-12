use ExtUtils::MakeMaker;

my $mm = MM->new({
    dist         => {
       PREOP	=> 'pod2text BDB.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
       COMPRESS	=> 'gzip -9v',
       SUFFIX	=> '.gz',
	            },
    NAME         => "AnyEvent::BDB",
    VERSION_FROM => "BDB.pm",
    PREREQ_PM    => {
       BDB       => 1.5,
       AnyEvent  => 3.81,
    },
});

$mm->flush;

