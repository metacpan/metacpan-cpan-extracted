use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'AnyEvent::STOMP',
    AUTHOR              =>	[
							q{Fulko Hew <fulko.hew@gmail.com},
							q{Michael S. Fischer <michael+cpan@dynamine.net>},
							],
    VERSION_FROM        => 'lib/AnyEvent/STOMP.pm',
    ABSTRACT_FROM       => 'lib/AnyEvent/STOMP.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
	'AnyEvent'      => 5.0,
	'common::sense' => 1.0,
	'Object::Event' => 1.21,
        'Test::More'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'AnyEvent-STOMP-*' },
);
