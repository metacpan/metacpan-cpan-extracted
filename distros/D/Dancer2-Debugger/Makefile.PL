use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Dancer2::Debugger',
    AUTHOR             => q{Peter Mottram (SysPete) <peter@sysnix.com>},
    VERSION_FROM       => 'lib/Dancer2/Debugger.pm',
    ABSTRACT_FROM      => 'lib/Dancer2/Debugger.pm',
    LICENSE            => 'perl_5',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    PREREQ_PM => {
        'Dancer2'                => '0.15',
        'Dancer2::Core::Hook'    => 0,
        'Dancer2::Core::Types'   => 0,
        'Dancer2::Plugin'        => 0,
        'Data::Dump'             => 0,
        'File::Spec'             => 0,
        'JSON::MaybeXS'          => 0,
        'Module::Find'           => 0,
        'Module::Runtime'        => 0,
        'Moo'                    => 2,
        'Moo::Role'              => 2,
        'namespace::clean'       => 0,
        'Plack::Debugger'        => 0,
        'Plack::Debugger::Panel' => 0,
        'Time::HiRes'            => 0,
    },
    dist       => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean      => { FILES    => 'Dancer2-Debugger-*' },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/SysPete/Dancer2-Debugger.git',
            bugtracker => 'https://github.com/SysPete/Dancer2-Debugger/issues',
            IRC        => 'irc://irc.perl.org/#dancer',
        },
    },
);
