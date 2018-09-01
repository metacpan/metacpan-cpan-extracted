use ExtUtils::MakeMaker;

use Canary::Stability AnyEvent::WebDriver => 1, 5.010;

my $mm = MM->new({
    dist         => {
       PREOP	=> 'pod2text WebDriver.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
       COMPRESS	=> 'gzip -9v',
       SUFFIX	=> '.gz',
	            },
    NAME         => "AnyEvent::WebDriver",
    VERSION_FROM => "WebDriver.pm",
    CONFIGURE_REQUIRES => { "ExtUtils::MakeMaker" => 6.52, "Canary::Stability" => 2012 },
    PREREQ_PM    => {
       common::sense  => 3.74,
       JSON::PP       => 2.273,
       AnyEvent       => 5.33,
       AnyEvent::HTTP => 2.22,
    },
    META_MERGE => {
       recommends => {
           JSON::XS => 3.04,
       },
    },
});

$mm->flush;

