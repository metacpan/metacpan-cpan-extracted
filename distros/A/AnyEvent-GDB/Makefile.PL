use ExtUtils::MakeMaker;

my $mm = MM->new({
    dist         => {
       PREOP	=> 'pod2text GDB.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
       COMPRESS	=> 'gzip -9v',
       SUFFIX	=> '.gz',
	            },
    NAME         => "AnyEvent::GDB",
    VERSION_FROM => "GDB.pm",
    PREREQ_PM        => {
       common::sense => 3.6,
       Task::Weaken  => 0,
       AnyEvent      => 6,
    },
});

$mm->flush;

