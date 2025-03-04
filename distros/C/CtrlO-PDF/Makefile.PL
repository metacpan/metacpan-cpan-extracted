use strict;
use warnings;
use ExtUtils::MakeMaker;

my $choice = 'Builder';  # API2 or Builder default prerequisite?
my $debug = 0;  # 1 to just dump contents

my %WriteMakefileArgs = (
    NAME                => 'CtrlO::PDF',
    AUTHOR              => q{Andy Beverley <andy@andybev.com>},
    VERSION_FROM        => 'lib/CtrlO/PDF.pm',
    ABSTRACT_FROM       => 'lib/CtrlO/PDF.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    BUILD_REQUIRES => {
        'Test::MockObject' => 0,
        'Test::More'  => 0,
        'Test::Warn'  => 0,
        'DateTime::Format::SQLite' => 0,
    },
    PREREQ_PM => {
        'Carp' => 0,
        'Image::Info' => 0,
        'Moo' => 0,
        'MooX::Types::MooseLike::Base' => 0,
        'PDF::Builder' => 3.025,
        'PDF::Table' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CtrlO-PDF*' },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/ctrlo/CtrlO-PDF',
            bugtracker => 'https://github.com/ctrlo/CtrlO-PDF/issues',
            homepage   => 'https://github.com/ctrlo/CtrlO-PDF/',
        },
    },

);

WriteMakefile(%WriteMakefileArgs);
