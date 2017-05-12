use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'AnyMQ::ZeroMQ',
    AUTHOR              => q{Mischa Spiegelmock <revmischa@cpan.org>},
    VERSION_FROM        => 'lib/AnyMQ/ZeroMQ.pm',
    ABSTRACT_FROM       => 'lib/AnyMQ/ZeroMQ.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Any::Moose' => 0,
        'AnyEvent' => 0,
        'JSON' => 0,
        'AnyEvent::ZeroMQ' => '0.34',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'AnyMQ-ZeroMQ-*' },
);
