use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Argon',
    AUTHOR              => q{"Jeff Ober" <"jeffober@gmail.com">},
    VERSION_FROM        => 'lib/Argon.pm',
    ABSTRACT            => 'A distributed execution platform for Perl',
        ($ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ('LICENSE'=> 'BSD License')
        : ()),
    PL_FILES            => {},
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Argon-*', },
    EXE_FILES           => [ 'bin/argon', ],
    PREREQ_PM => {
        'AnyEvent'          => 0,
        'Const::Fast'       => 0,
        'Coro'              => 0,
        'Coro::ProcessPool' => '0.16',
        'Coro::PrioChannel' => '0.005',
        'Guard'             => 0,
        'Data::UUID'        => 0,
        'Log::Log4perl'     => 0,
        'Module::Load'      => 0,
        'Moo'               => 0,
        'MooX::HandlesVia'  => 0,
        'Types::Standard'   => 0,
    },
    BUILD_REQUIRES => {
        'List::Util'       => 0,
        'Test::More'       => 0,
        'Test::TinyMocker' => 0,
        'Sub::Override'    => 0,
    },
);
