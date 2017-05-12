use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'AnyEvent::Emitter',
    AUTHOR              => q{fukai <iakuf@163.com>},
    VERSION_FROM        => 'lib/AnyEvent/Emitter.pm',
    ABSTRACT_FROM       => 'lib/AnyEvent/Emitter.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'    => 0,
        'Scalar::Util'  => 0,
    },
    META_MERGE => {
        resources => {
            license     => 'http://dev.perl.org/licenses/',
            bugtracker  => 'https://github.com/iakuf/AnyEvent-Emitter/issues',
            repository  => 'https://github.com/iakuf/AnyEvent-Emitter.git',
        },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'AnyEvent-Emitter-*' },
);
