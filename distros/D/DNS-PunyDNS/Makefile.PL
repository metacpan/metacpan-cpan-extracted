use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'DNS::PunyDNS',
    AUTHOR              => q{Bruno Martins <bruno-martins@telecom.pt>},
    VERSION_FROM        => 'lib/DNS/PunyDNS.pm',
    ABSTRACT_FROM       => 'lib/DNS/PunyDNS.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
		'LWP::UserAgent' => 0,
		'XML::Simple' => 0,
		'Readonly' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'DNS-PunyDNS-*' },
);
