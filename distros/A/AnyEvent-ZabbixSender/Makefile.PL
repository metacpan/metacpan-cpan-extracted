use Canary::Stability AnyEvent::ZabbixSender => 1, 5.010;

use ExtUtils::MakeMaker;

my $mm = MM->new({
    dist         => {
       PREOP	=> 'pod2text ZabbixSender.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
       COMPRESS	=> 'gzip -9v',
       SUFFIX	=> '.gz',
	            },
    NAME         => "AnyEvent::ZabbixSender",
    VERSION_FROM => "ZabbixSender.pm",
    CONFIGURE_REQUIRES => { "ExtUtils::MakeMaker" => 6.52, "Canary::Stability" => 0 },
    PREREQ_PM    => {
       common::sense => 3.74,
       AnyEvent      => 7.0,
       Task::Weaken  => 0,
       JSON::PP      => 2.2,
    },
    META_MERGE => {
       "meta-spec" => { version => 2 },
       prereqs => {
          runtime => {
             recommends => { JSON::XS => 3 },
          },
       },
    },
});

$mm->flush;

