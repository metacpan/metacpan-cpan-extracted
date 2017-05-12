use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'AnyEvent::FreeSWITCH',
    AUTHOR              => q{William King <william.king@quentustech.com>},
    VERSION_FROM        => 'lib/AnyEvent/FreeSWITCH.pm',
    ABSTRACT_FROM       => 'lib/AnyEvent/FreeSWITCH.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'bsd')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'    => 0,
	'ESL'           => 0,
	'AnyEvent'      => 0,
	'Object::Event' => 0.7,
	'Carp'          => 0,
    },
    PREREQ_FATAL        => 1,
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'AnyEvent-FreeSWITCH-*' },
);
