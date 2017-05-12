use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'AnyMQ::RawSocket',
    AUTHOR              => q{Mischa Spiegelmock <revmischa@cpan.org>},
    VERSION_FROM        => 'lib/AnyMQ/RawSocket.pm',
    ABSTRACT_FROM       => 'lib/AnyMQ/RawSocket.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'AnyMQ' => 0,
        'Any::Moose' => 0,
        'JSON' => 0,
        'AnyEvent::Socket' => 0,
        'AnyEvent::Handle' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'AnyMQ-RawSocket-*' },
);
