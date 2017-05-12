use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Audio::Play::MPlayer',
    AUTHOR              => q{Luke Poskitt <ltp@cpan.org>},
    VERSION_FROM        => 'lib/Audio/Play/MPlayer.pm',
    ABSTRACT_FROM       => 'lib/Audio/Play/MPlayer.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'IPC::Open3' => 0,
        'IO::Handle' => 0,
        'Class::Accessor::Fast' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Audio-Play-MPlayer-*' },
);
