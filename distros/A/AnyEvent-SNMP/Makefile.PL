use ExtUtils::MakeMaker;

my $mm = MM->new({
    dist         => {
       PREOP	=> 'pod2text SNMP.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
       COMPRESS	=> 'gzip -9v',
       SUFFIX	=> '.gz',
	            },
    NAME         => "AnyEvent::SNMP",
    VERSION_FROM => "SNMP.pm",
    PREREQ_PM    => {
       common::sense => 3.3,
       Net::SNMP     => 5,
       AnyEvent      => 5.23,
    },
});

$mm->flush;

