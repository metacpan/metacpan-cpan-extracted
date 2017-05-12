use ExtUtils::MakeMaker;

my $mm = MM->new({
    dist         => {
       PREOP	=> 'pod2text GPSD.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
       COMPRESS	=> 'gzip -9v',
       SUFFIX	=> '.gz',
	            },
    NAME         => "AnyEvent::GPSD",
    VERSION_FROM => "GPSD.pm",
    PREREQ_PM    => {
       AnyEvent     => 4.16,
       Geo::Forward => 0,
    },
});

$mm->flush;

