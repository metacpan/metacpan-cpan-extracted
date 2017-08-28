use ExtUtils::MakeMaker;

use Canary::Stability AnyEvent::DBI => 1, 5.008;

my $mm = MM->new({
    dist         => {
       PREOP	=> 'pod2text DBI.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
       COMPRESS	=> 'gzip -9v',
       SUFFIX	=> '.gz',
	            },
    NAME         => "AnyEvent::DBI",
    VERSION_FROM => "DBI.pm",
    CONFIGURE_REQUIRES => {
       "ExtUtils::MakeMaker" => 6.6,
       "Canary::Stability" => 0,
    },
    PREREQ_PM        => {
       AnyEvent        => 4.15,
       DBI             => 1.0,
       common::sense   => 3.3,
       CBOR::XS        => 1.7,
       Convert::Scalar => 1.12,
       AnyEvent::Fork  => 1.31,
    },
});

$mm->flush;

