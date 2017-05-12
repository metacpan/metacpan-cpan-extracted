use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'AnyEvent::Handle::ZeroMQ',
    AUTHOR              => q{Cindy Wang (CindyLinz)},
    VERSION_FROM        => 'lib/AnyEvent/Handle/ZeroMQ.pm',
    ABSTRACT_FROM       => 'lib/AnyEvent/Handle/ZeroMQ.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'AnyEvent' => 5.34,
	'ZeroMQ' => 0.15,
	'Scalar::Util' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'AnyEvent-Handle-ZeroMQ-*' },
);
